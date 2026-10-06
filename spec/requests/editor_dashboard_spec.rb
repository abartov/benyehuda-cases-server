require 'rails_helper'

RSpec.describe 'Editor dashboard', type: :request do
  let(:editor) { create(:user, :editor, :active_user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(editor)
    allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
  end

  it 'hides approved tasks from the editing tasks list but shows others' do
    create(:approved_task, name: 'ApprovedTaskXyz', editor: editor)
    create(:waits_for_editor_approve_task, name: 'WaitingTaskXyz', editor: editor)

    get dashboard_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include('WaitingTaskXyz')
    expect(response.body).not_to include('ApprovedTaskXyz')
  end
end
