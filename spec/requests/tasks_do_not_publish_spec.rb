require 'rails_helper'

RSpec.describe 'Tasks assignment popup with do_not_publish flag', type: :request do
  let(:editor) { create(:user, :editor, :active_user) }
  let(:volunteer) { create(:user, :volunteer, :active_user) }

  let!(:unassigned_state) { create(:task_state, name: 'unassigned', value: 'unassigned_value') }
  let!(:assigned_state)   { create(:task_state, name: 'assigned',   value: 'assigned_value') }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(editor)
    allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
  end

  describe 'GET /tasks (assignment popup index)' do
    let!(:publishable_task)     { create(:unassigned_task, do_not_publish: false, name: 'Publishable Task') }
    let!(:do_not_publish_task)  { create(:unassigned_task, do_not_publish: true,  name: 'Do Not Publish Task') }

    it 'includes tasks not marked do_not_publish and excludes those marked do_not_publish' do
      get tasks_path, params: { assignee_id: volunteer.id }, xhr: true

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Publishable Task')
      expect(response.body).not_to include('Do Not Publish Task')
    end
  end
end
