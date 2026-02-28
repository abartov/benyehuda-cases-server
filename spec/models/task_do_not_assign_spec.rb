require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'do_not_assign flag' do
    let(:editor) { create(:user, :editor, :active_user) }
    let(:volunteer) { create(:user, :volunteer, :active_user) }

    before do
      # Stub notifications to avoid dependency on TaskState DB records in unit tests
      allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
    end

    describe 'validation' do
      it 'is valid when do_not_assign is false and an assignee is set' do
        task = create(:unassigned_task, do_not_assign: false)
        task.assignee = volunteer
        task.editor = editor
        expect(task).to be_valid
      end

      it 'is invalid when do_not_assign is true and an assignee is being set' do
        task = create(:unassigned_task, do_not_assign: true)
        task.assignee = volunteer
        task.editor = editor
        expect(task).not_to be_valid
        expect(task.errors[:base]).to include(I18n.t('tasks.do_not_assign_error'))
      end

      it 'is valid when do_not_assign is true but no assignee is set' do
        task = create(:unassigned_task, do_not_assign: true)
        expect(task.assignee).to be_nil
        expect(task).to be_valid
      end
    end

    describe 'assign_by_user_ids!' do
      it 'raises RecordInvalid when task is marked do_not_assign' do
        task = create(:unassigned_task, do_not_assign: true)
        expect {
          task.assign_by_user_ids!(editor.id, volunteer.id)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'succeeds when task is not marked do_not_assign' do
        task = create(:unassigned_task, do_not_assign: false)
        expect {
          task.assign_by_user_ids!(editor.id, volunteer.id)
        }.not_to raise_error
        expect(task.reload.assignee).to eq(volunteer)
      end
    end

    describe 'default value' do
      it 'defaults to false' do
        task = create(:unassigned_task)
        expect(task.do_not_assign).to eq(false)
      end
    end
  end
end
