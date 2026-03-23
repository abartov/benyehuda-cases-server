require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'do_not_publish flag' do
    before do
      allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
    end

    describe 'default value' do
      it 'defaults to false' do
        task = create(:unassigned_task)
        expect(task.do_not_publish).to eq(false)
      end
    end

    describe 'cloning via dup' do
      it 'copies do_not_publish when task is duped' do
        task = create(:unassigned_task, do_not_publish: true)
        cloned = task.dup
        expect(cloned.do_not_publish).to eq(true)
      end

      it 'copies do_not_publish false when task is duped' do
        task = create(:unassigned_task, do_not_publish: false)
        cloned = task.dup
        expect(cloned.do_not_publish).to eq(false)
      end
    end
  end
end
