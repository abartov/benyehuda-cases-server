require 'rails_helper'
require 'csv'

RSpec.describe 'Admin tasks CSV download', type: :request do
  let(:admin_user) { create(:user, :admin, :active_user) }
  let(:current) { admin_user }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(current)
    allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
  end

  def parsed_csv
    CSV.parse(response.body.delete_prefix("\uFEFF"))
  end

  describe 'GET /admin/tasks.csv' do
    let!(:task_few_files)  { create(:task, name: 'AlphaFew',  documents_count: 1) }
    let!(:task_many_files) { create(:task, name: 'AlphaMany', documents_count: 9, state: 'assigned') }
    let!(:other_task)      { create(:task, name: 'BetaTask',  documents_count: 5, genre: 'שירה') }

    it 'returns a CSV with the listing columns and a task URL column after the name' do
      get admin_tasks_path(format: :csv)

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('attachment')

      header, *rows = parsed_csv
      expect(header).to eq([I18n.t('tasks.csv.id'), _('Creater'), _('Last Updated'), _('Name'),
                            I18n.t('tasks.csv.task_url'), I18n.t('tasks.csv.genre'), _('Kind'), _('Editor'),
                            _('Assignee'), _('State'), _('Files')])
      row = rows.find { |r| r[3] == 'BetaTask' }
      expect(row).to eq([other_task.id.to_s, other_task.creator.name, other_task.updated_at.to_s(:db), 'BetaTask',
                         task_url(other_task), 'שירה', other_task.kind.name, other_task.editor.name,
                         other_task.assignee.name, Task.textify_state(other_task.state), '5'])
    end

    it 'leaves editor and assignee empty when the task has none' do
      unassigned = create(:unassigned_task, name: 'NobodyTask')

      get admin_tasks_path(format: :csv)

      row = parsed_csv.find { |r| r[3] == 'NobodyTask' }
      expect(row[0]).to eq(unassigned.id.to_s)
      expect(row.values_at(7, 8)).to eq(['', ''])
    end

    it 'quotes fields containing semicolons, which would otherwise break the structure in some spreadsheets' do
      create(:task, name: 'Part one; part two', creator: create(:user, :admin, name: 'Cohen; Levi'))

      get admin_tasks_path(format: :csv)

      body = response.body.delete_prefix("\uFEFF")
      expect(body).to include('"Part one; part two"')
      expect(body).to include('"Cohen; Levi"')
      row = CSV.parse(body).find { |r| r[3].to_s.start_with?('Part one') }
      expect(row.size).to eq(11)
      expect(row.values_at(1, 3)).to eq(['Cohen; Levi', 'Part one; part two'])
    end

    it 'escapes quotes and commas in titles' do
      create(:task, name: 'Say "hi", then leave')

      get admin_tasks_path(format: :csv)

      row = parsed_csv.find { |r| r[3].to_s.start_with?('Say') }
      expect(row.size).to eq(11)
      expect(row[3]).to eq('Say "hi", then leave')
    end

    it 'includes all matching tasks regardless of pagination' do
      get admin_tasks_path(format: :csv), params: { per_page: 1, page: 2 }

      expect(parsed_csv.drop(1).map { |r| r[3] }).to contain_exactly('AlphaFew', 'AlphaMany', 'BetaTask')
    end

    it 'applies the current filters' do
      get admin_tasks_path(format: :csv), params: { state: 'assigned' }

      expect(parsed_csv.drop(1).map { |r| r[3] }).to eq(%w[AlphaMany])
    end

    it 'applies the current sorting across all pages' do
      get admin_tasks_path(format: :csv),
          params: { per_page: 1, order_by: { property: 'tasks.documents_count', dir: 'DESC' } }

      expect(parsed_csv.drop(1).map { |r| r[3] }).to eq(%w[AlphaMany BetaTask AlphaFew])
    end

    it 'neutralizes names that a spreadsheet would treat as formulas' do
      create(:task, name: '=HYPERLINK("http://evil.example","x")')
      create(:task, name: '-ספר', creator: create(:user, :admin, name: '@cmd'))

      get admin_tasks_path(format: :csv)

      rows = parsed_csv.drop(1)
      expect(rows.map { |r| r[3] }).to include(%q('=HYPERLINK("http://evil.example","x")), "'-ספר", 'BetaTask')
      expect(rows.map { |r| r[1] }).to include("'@cmd")
    end

    context 'when the search is a text query (served by Sphinx, which can only be paged through)' do
      let(:pages) do
        [WillPaginate::Collection.create(1, 1000, 1500) { |p| p.replace([task_few_files, task_many_files]) },
         WillPaginate::Collection.create(2, 1000, 1500) { |p| p.replace([other_task]) }]
      end

      it 'fetches every page of results' do
        allow(Task).to receive(:filter) { |opts| pages[opts[:page] - 1] }

        get admin_tasks_path(format: :csv), params: { query: 'Alpha' }

        expect(parsed_csv.drop(1).map { |r| r[3] }).to eq(%w[AlphaFew AlphaMany BetaTask])
        expect(Task).to have_received(:filter).twice
      end

      it 'redirects with an error when Sphinx is unavailable' do
        allow(Task).to receive(:filter).and_raise(Riddle::ConnectionError)

        get admin_tasks_path(format: :csv), params: { query: 'Alpha' }

        expect(response).to redirect_to('/')
      end
    end

    context 'when the user is a volunteer' do
      let(:current) { create(:user, :volunteer, :active_user) }

      it 'does not export anything' do
        get admin_tasks_path(format: :csv)

        expect(response).to redirect_to(dashboard_path)
        expect(response.body).not_to include('AlphaFew')
      end
    end
  end

  describe 'GET /admin/tasks' do
    it 'renders a download link that preserves filters and sorting but not the page' do
      get admin_tasks_path, params: { state: 'assigned', order_by: { property: 'tasks.documents_count', dir: 'DESC' }, page: 2 }

      link = Nokogiri::HTML(response.body).css('a').find { |a| a.text.strip == I18n.t('tasks.csv.download') }
      expect(link).to be_present
      uri = URI.parse(link['href'])
      expect(uri.path).to eq('/admin/tasks.csv')
      query = Rack::Utils.parse_nested_query(uri.query)
      expect(query).to include('state' => 'assigned', 'order_by' => { 'property' => 'tasks.documents_count', 'dir' => 'DESC' })
      expect(query).not_to have_key('page')
    end
  end

  describe 'GET /tasks' do
    it 'no longer offers a CSV download' do
      get tasks_path

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include(I18n.t('tasks.csv.download'))
    end
  end
end
