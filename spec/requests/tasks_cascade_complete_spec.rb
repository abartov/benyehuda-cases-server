# encoding: utf-8
# Tests for the flash notice when cascading ready_to_publish to parent tasks.
require 'rails_helper'

RSpec.describe 'Tasks cascade complete flash notice', type: :request do
  let(:editor)    { create(:user, :editor, :active_user) }
  let(:volunteer) { create(:user, :volunteer, :active_user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:require_user).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(editor)
    allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
  end

  def other_task_creat_task(kind:)
    create(:task,
           kind_id:  kind,
           state:    'other_task_creat',
           editor:   editor,
           assignee: volunteer)
  end

  def approved_task(kind:, parent: nil)
    create(:task,
           kind_id:   kind,
           state:     'approved',
           editor:    editor,
           assignee:  volunteer,
           parent_id: parent&.id)
  end

  context 'completing a הגהה task whose parent הקלדה is also updated' do
    let!(:parent_typing) { other_task_creat_task(kind: :הקלדה) }
    let!(:proofing_task) { approved_task(kind: :הגהה, parent: parent_typing) }

    it 'redirects to the task and sets flash mentioning the parent task name' do
      put task_path(proofing_task), params: { event: 'complete' }

      expect(response).to redirect_to(task_path(proofing_task))
      expect(flash[:notice]).to include(parent_typing.name)
    end
  end

  context 'completing a הגהה task with no eligible parent' do
    let!(:proofing_task) { approved_task(kind: :הגהה) }

    it 'sets the generic Task updated flash notice' do
      put task_path(proofing_task), params: { event: 'complete' }

      expect(response).to redirect_to(task_path(proofing_task))
      expect(flash[:notice]).not_to be_nil
      expect(flash[:notice]).not_to include('parent_names')
    end
  end

  context 'completing an עריכה_טכנית task with a הגהה → הקלדה ancestor chain' do
    let!(:grandparent_typing) { other_task_creat_task(kind: :הקלדה) }
    let!(:parent_proofing) do
      other_task_creat_task(kind: :הגהה).tap { |t| t.update_column(:parent_id, grandparent_typing.id) }
    end
    let!(:tech_edit_task) { approved_task(kind: :עריכה_טכנית, parent: parent_proofing) }

    it 'sets flash mentioning both ancestor task names' do
      put task_path(tech_edit_task), params: { event: 'complete' }

      expect(response).to redirect_to(task_path(tech_edit_task))
      expect(flash[:notice]).to include(parent_proofing.name)
      expect(flash[:notice]).to include(grandparent_typing.name)
    end

    it 'transitions both ancestors to ready_to_publish' do
      put task_path(tech_edit_task), params: { event: 'complete' }

      expect(parent_proofing.reload.state).to eq('ready_to_publish')
      expect(grandparent_typing.reload.state).to eq('ready_to_publish')
    end
  end
end
