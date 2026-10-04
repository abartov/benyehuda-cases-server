require 'rails_helper'
require 'csv'

RSpec.describe 'Tasks index CSV download', type: :request do
  let(:editor) { create(:user, :editor, :active_user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(editor)
    allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
  end

  def parsed_csv
    CSV.parse(response.body.delete_prefix("﻿"))
  end

  describe 'GET /tasks.csv' do
    let!(:task_few_files)  { create(:unassigned_task, name: 'AlphaFew',  documents_count: 1) }
    let!(:task_many_files) { create(:unassigned_task, name: 'AlphaMany', documents_count: 9) }
    let!(:other_task)      { create(:unassigned_task, name: 'BetaTask',  documents_count: 5) }

    it 'returns a CSV with the listing columns and a task URL column after the name' do
      get tasks_path(format: :csv)

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('attachment')

      header, *rows = parsed_csv
      expect(header).to eq([_('Name'), I18n.t('tasks.csv.task_url'), _('Kind'), _('State'), _('Files'), _('Progress')])
      row = rows.find { |r| r[0] == 'BetaTask' }
      expect(row[1]).to eq(task_url(other_task))
      expect(row[2]).to eq(other_task.kind.name)
      expect(row[3]).to eq(Task.textify_state(other_task.state))
      expect(row[4]).to eq('5')
      expect(row[5]).to eq("#{other_task.percent_done}%")
    end

    it 'includes all matching tasks regardless of pagination' do
      get tasks_path(format: :csv), params: { per_page: 1, page: 2 }

      expect(parsed_csv.drop(1).map(&:first)).to contain_exactly('AlphaFew', 'AlphaMany', 'BetaTask')
    end

    it 'applies the current filters and sorting' do
      get tasks_path(format: :csv), params: { query: 'Alpha', order_by: { property: 'documents_count', dir: 'DESC' } }

      expect(parsed_csv.drop(1).map(&:first)).to eq(%w[AlphaMany AlphaFew])
    end

    context 'when sorting by progress' do
      let(:volunteer) { create(:user, :volunteer, :active_user) }

      before do
        # AlphaFew: 100% done, AlphaMany: 50% done, BetaTask: 0% done
        add_doc(task_few_files, 'a.jpg', done: true)
        add_doc(task_many_files, 'b.jpg', done: true)
        add_doc(task_many_files, 'c.jpg')
        add_doc(other_task, 'd.jpg')
      end

      def add_doc(task, filename, done: false)
        create(:document, task: task, file_file_name: filename, file_content_type: 'application/octet-stream',
                          file_file_size: 100, user_id: volunteer.id, done: done)
      end

      it 'orders ascending when dir is ASC' do
        get tasks_path(format: :csv), params: { sort_by: 'percent_done', dir: 'ASC' }

        expect(parsed_csv.drop(1).map(&:first)).to eq(%w[BetaTask AlphaMany AlphaFew])
      end

      it 'reverses the order when dir is DESC' do
        get tasks_path(format: :csv), params: { sort_by: 'percent_done', dir: 'DESC' }

        expect(parsed_csv.drop(1).map(&:first)).to eq(%w[AlphaFew AlphaMany BetaTask])
      end

      it 'uses a constant number of document queries regardless of the number of tasks' do
        count_queries = lambda do
          queries = []
          callback = ->(*, payload) { queries << payload[:sql] if payload[:sql] =~ /FROM .documents./ }
          ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
            get tasks_path(format: :csv), params: { sort_by: 'percent_done', dir: 'ASC' }
          end
          queries.size
        end
        baseline = count_queries.call
        create_list(:unassigned_task, 3)

        expect(count_queries.call).to eq(baseline)
      end
    end

    it 'neutralizes task names that a spreadsheet would treat as formulas' do
      create(:unassigned_task, name: '=HYPERLINK("http://evil.example","x")')
      create(:unassigned_task, name: '-ספר')

      get tasks_path(format: :csv)

      names = parsed_csv.drop(1).map(&:first)
      expect(names).to include(%q('=HYPERLINK("http://evil.example","x")), "'-ספר", 'BetaTask')
    end
  end

  describe 'GET /tasks' do
    it 'renders a download link that preserves filters and sorting but not the page' do
      get tasks_path, params: { query: 'Alpha', order_by: { property: 'documents_count', dir: 'DESC' }, page: 2 }

      link = Nokogiri::HTML(response.body).css('a').find { |a| a.text.strip == I18n.t('tasks.csv.download') }
      expect(link).to be_present
      uri = URI.parse(link['href'])
      expect(uri.path).to eq('/tasks.csv')
      query = Rack::Utils.parse_nested_query(uri.query)
      expect(query).to include('query' => 'Alpha', 'order_by' => { 'property' => 'documents_count', 'dir' => 'DESC' })
      expect(query).not_to have_key('page')
    end
  end
end
