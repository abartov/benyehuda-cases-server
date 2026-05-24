require 'rails_helper'

RSpec.describe 'Tasks assignment popup sorting', type: :request do
  let(:editor) { create(:user, :editor, :active_user) }
  let(:volunteer) { create(:user, :volunteer, :active_user) }

  let!(:unassigned_state) { create(:task_state, name: 'unassigned', value: 'unassigned_value') }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(editor)
    allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
  end

  describe 'GET /tasks (assignment popup) sorting by documents_count' do
    let!(:task_few_files)  { create(:unassigned_task, name: 'FewFilesTask',  documents_count: 1) }
    let!(:task_many_files) { create(:unassigned_task, name: 'ManyFilesTask', documents_count: 9) }

    it 'sorts ascending by documents_count' do
      get tasks_path, params: { assignee_id: volunteer.id, order_by: { property: 'documents_count', dir: 'ASC' } }, xhr: true

      expect(response).to have_http_status(:success)
      expect(response.body.index('FewFilesTask')).to be < response.body.index('ManyFilesTask')
    end

    it 'sorts descending by documents_count' do
      get tasks_path, params: { assignee_id: volunteer.id, order_by: { property: 'documents_count', dir: 'DESC' } }, xhr: true

      expect(response).to have_http_status(:success)
      expect(response.body.index('ManyFilesTask')).to be < response.body.index('FewFilesTask')
    end

    it 'renders sort links with data-remote in the response' do
      get tasks_path, params: { assignee_id: volunteer.id }, xhr: true

      expect(response).to have_http_status(:success)
      expect(response.body).to include('data-remote')
      expect(response.body).to include('documents_count')
    end

    it 'ignores a crafted SQL injection property and returns all tasks unsorted' do
      get tasks_path, params: { assignee_id: volunteer.id, order_by: { property: '1; DROP TABLE tasks--', dir: 'ASC' } }, xhr: true

      expect(response).to have_http_status(:success)
      expect(response.body).to include('FewFilesTask')
      expect(response.body).to include('ManyFilesTask')
    end
  end

  describe 'GET /tasks (assignment popup) name search' do
    let!(:matching_task)    { create(:unassigned_task, name: 'AlphaTask') }
    let!(:nonmatching_task) { create(:unassigned_task, name: 'BetaTask') }

    it 'filters tasks by name substring' do
      get tasks_path, params: { assignee_id: volunteer.id, query: 'Alpha' }, xhr: true

      expect(response).to have_http_status(:success)
      expect(response.body).to include('AlphaTask')
      expect(response.body).not_to include('BetaTask')
    end

    it 'returns all tasks when query is blank' do
      get tasks_path, params: { assignee_id: volunteer.id, query: '' }, xhr: true

      expect(response).to have_http_status(:success)
      expect(response.body).to include('AlphaTask')
      expect(response.body).to include('BetaTask')
    end

    it 'renders the query field in the filter form' do
      get tasks_path, params: { assignee_id: volunteer.id }, xhr: true

      expect(response).to have_http_status(:success)
      # JS response escapes quotes; check for the field name attribute
      expect(response.body).to include('name=\\"query\\"')
    end

    it 'preserves query param in sort links' do
      get tasks_path, params: { assignee_id: volunteer.id, query: 'Alpha' }, xhr: true

      expect(response).to have_http_status(:success)
      expect(response.body).to include('query%5D=Alpha').or include('query=Alpha')
    end
  end
end
