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
  end
end
