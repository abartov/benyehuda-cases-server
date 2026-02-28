require 'rails_helper'

RSpec.describe 'Assignments with do_not_assign flag', type: :request do
  let(:editor) { create(:user, :editor, :active_user) }
  let(:volunteer) { create(:user, :volunteer, :active_user) }

  # TaskState records are required by Task.textify_state (used in views and notifications)
  let!(:unassigned_state) { create(:task_state, name: 'unassigned', value: 'unassigned_value') }
  let!(:assigned_state)   { create(:task_state, name: 'assigned',   value: 'assigned_value') }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(editor)
    # Stub notifications to avoid dependency on ActionMailer in unit-style request specs
    allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
  end

  describe 'POST /tasks/:task_id/assignment (quick assign)' do
    context 'when task has do_not_assign set to true' do
      let(:task) { create(:unassigned_task, do_not_assign: true) }

      it 'does not assign the task and redirects with an error flash' do
        post task_assignment_path(task), params: { assignee_id: volunteer.id }

        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(task.reload.assignee).to be_nil
      end
    end

    context 'when task has do_not_assign set to false' do
      let(:task) { create(:unassigned_task, do_not_assign: false) }

      it 'assigns the task successfully' do
        post task_assignment_path(task), params: { assignee_id: volunteer.id }

        expect(response).to redirect_to(dashboard_path)
        expect(task.reload.assignee).to eq(volunteer)
      end
    end
  end

  describe 'GET /tasks (assignment popup index)' do
    let!(:assignable_task) { create(:unassigned_task, do_not_assign: false, name: 'Assignable Task') }
    let!(:blocked_task)    { create(:unassigned_task, do_not_assign: true,  name: 'Blocked Task') }

    it 'includes assignable tasks and excludes tasks marked do_not_assign' do
      get tasks_path, params: { assignee_id: volunteer.id }, xhr: true

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Assignable Task')
      expect(response.body).not_to include('Blocked Task')
    end
  end
end
