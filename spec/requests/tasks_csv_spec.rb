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
