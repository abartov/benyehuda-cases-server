# encoding: utf-8
# Regression tests for Sphinx search integration with the kind_id enum.
#
# Two regressions motivated these tests:
#
#   1. task_index.rb used `indexes kind.name` (joining the deleted task_kinds
#      table), producing an empty SQL column expression that broke indexing:
#        SELECT ..., `tasks`.`priority` AS `priority`,  AS `kind`, ...
#      Fixed by replacing with `has :kind_id, type: :integer`.
#
#   2. Task.filter put kind_id in `conditions` (ThinkingSphinx full-text MATCH)
#      instead of `with` (numeric attribute filter), producing the query
#        MATCH('query @kind_id 1')
#      and the error "no enabled local indexes to search".
#      Fixed by using `search_opts[:with][:kind_id]` in the Sphinx code path.
#
require 'rails_helper'

RSpec.describe 'Task Sphinx integration', type: :model do
  # ── Index configuration ────────────────────────────────────────────────────
  #
  # These tests render the Sphinx configuration from the index definition
  # without starting searchd, then assert the generated SQL and attribute
  # declarations are well-formed.
  describe 'Sphinx index configuration for Task' do
    # Extract only the task_core_0 source block to avoid false matches
    # from the user_core_0 source (which legitimately has `sql_field_string = kind`).
    subject(:task_source) do
      ThinkingSphinx::Configuration.instance.render[/source task_core_0\b.*?^}/m]
    end

    it 'has a task_core_0 source block' do
      expect(task_source).not_to be_nil
    end

    it 'declares kind_id as a numeric uint attribute' do
      # `has :kind_id, type: :integer` must produce sql_attr_uint, not a field.
      # Regression: was `indexes kind.name` → sql_field_string = kind.
      expect(task_source).to include('sql_attr_uint = kind_id')
    end

    it 'does not declare kind as a full-text field in the task source' do
      # Regression: `indexes kind.name` produced `sql_field_string = kind`.
      expect(task_source).not_to match(/sql_field_string = kind\b/)
    end

    it 'selects kind_id directly from the tasks table' do
      # Regression: broken JOIN to deleted task_kinds produced an empty expr.
      expect(task_source).to include('`tasks`.`kind_id` AS `kind_id`')
    end

    it 'has no empty SQL column expression in the SELECT' do
      # Regression: produced `,  AS `kind`` (note the missing column expr).
      expect(task_source).not_to match(/,\s*AS `\w+`/)
    end

    it 'has no double-comma in the GROUP BY clause' do
      # The empty kind expr also left a dangling comma in the GROUP BY.
      expect(task_source).not_to match(/GROUP BY.*,\s*,/m)
    end
  end

  # ── Task.filter — Sphinx search path ──────────────────────────────────────
  #
  # When opts[:query] is present, Task.filter delegates to ThinkingSphinx
  # Task.search.  Integer attributes like kind_id must go in the `with` hash
  # (numeric attribute filter), NOT in `conditions` (MATCH() field search).
  #
  # Task.filter receives ActionController::Parameters in production (indifferent
  # access), so we use HashWithIndifferentAccess here to match that behaviour.
  # Plain symbol-key hashes would cause the early-return check
  # `(opts.keys & SEARCH_KEYS).blank?` to silently skip all filtering, and
  # symbol access like opts[:query] to fail on string-keyed hashes.
  describe 'Task.filter Sphinx search path' do
    def filter_opts(hash)
      ActiveSupport::HashWithIndifferentAccess.new(hash)
    end

    def stub_search(&block)
      # Capture the options hash passed to Task.search and yield it.
      # Returns an empty paginated collection so callers don't blow up.
      expect(Task).to receive(:search) do |_query, opts|
        block.call(opts) if block
        WillPaginate::Collection.new(1, 20, 0)
      end
    end

    context 'when kind filter is provided' do
      it 'puts kind_id integer in the :with hash' do
        stub_search do |opts|
          expect(opts[:with]).to include(kind_id: Task.kind_ids[:הגהה])
        end
        Task.filter(filter_opts(query: 'test', kind: 'הגהה', page: 1, per_page: 20))
      end

      it 'does not put kind_id in the :conditions hash' do
        # Regression: conditions[:kind_id] = integer becomes `@kind_id 21`
        # inside MATCH(), which Sphinx rejects with "no enabled local indexes".
        stub_search do |opts|
          expect(opts[:conditions]).not_to have_key(:kind_id)
        end
        Task.filter(filter_opts(query: 'test', kind: 'הגהה', page: 1, per_page: 20))
      end

      it 'passes the correct integer value for each kind key' do
        Task.kind_ids.each do |key, int_value|
          stub_search do |opts|
            expect(opts[:with][:kind_id]).to eq(int_value)
          end
          Task.filter(filter_opts(query: 'test', kind: key.to_s, page: 1, per_page: 20))
        end
      end
    end

    context 'when no kind filter is provided' do
      it 'does not add kind_id to :with' do
        stub_search do |opts|
          expect(opts[:with]).not_to have_key(:kind_id)
        end
        Task.filter(filter_opts(query: 'test', page: 1, per_page: 20))
      end
    end
  end

  # ── Task.filter — ActiveRecord path ───────────────────────────────────────
  #
  # When opts[:query] is blank, Task.filter builds a WHERE clause instead of
  # calling Sphinx. The enum string key (e.g. "הגהה") goes in conditions and
  # ActiveRecord translates it to the integer for SQL.
  describe 'Task.filter ActiveRecord (non-Sphinx) path' do
    def filter_opts(hash)
      ActiveSupport::HashWithIndifferentAccess.new(hash)
    end

    let!(:typing_task)   { create(:task, kind_id: :הקלדה, state: 'unassigned', assignee: nil, editor: nil) }
    let!(:proofing_task) { create(:task, kind_id: :הגהה,  state: 'unassigned', assignee: nil, editor: nil) }

    it 'returns only tasks matching the kind filter' do
      result = Task.filter(filter_opts(kind: 'הגהה', page: 1, per_page: 20))
      expect(result.map(&:id)).to     include(proofing_task.id)
      expect(result.map(&:id)).not_to include(typing_task.id)
    end

    it 'returns all tasks when no kind filter is given' do
      result = Task.filter(filter_opts(page: 1, per_page: 20))
      ids = result.map(&:id)
      expect(ids).to include(typing_task.id, proofing_task.id)
    end
  end
end
