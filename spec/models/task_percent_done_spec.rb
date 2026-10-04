require 'rails_helper'

RSpec.describe Task, type: :model do
  describe '.percent_done_by_task_id' do
    let(:volunteer) { create(:user, :volunteer, :active_user) }
    let(:task_half) { create(:unassigned_task) }
    let(:task_none) { create(:unassigned_task) }
    let(:task_empty) { create(:unassigned_task) }

    before do
      allow_any_instance_of(Task).to receive(:delayed_notify_on_changes)
      add_doc(task_half, 'p1.jpg', done: true)
      add_doc(task_half, 'p2.pdf')
      add_doc(task_half, 'notes.txt')             # not counted as a file to do
      add_doc(task_half, 'p3.png', deleted: true) # deleted documents are ignored
      add_doc(task_none, 'p1.JPG')                # extension match is case-sensitive, as in #files_todo
      add_doc(task_none, 'noextension')
    end

    def add_doc(task, filename, done: false, deleted: false)
      create(:document, task: task, file_file_name: filename, file_content_type: 'application/octet-stream',
                        file_file_size: 100, user_id: volunteer.id, done: done,
                        deleted_at: deleted ? Time.zone.now : nil)
    end

    it 'matches #percent_done for each task' do
      tasks = [task_half, task_none, task_empty].map(&:reload)
      result = described_class.percent_done_by_task_id(tasks.map(&:id))

      expect(result).to eq(tasks.to_h { |t| [t.id, t.percent_done] })
      expect(result[task_half.id]).to eq(50)
      expect(result[task_none.id]).to eq(0)
      expect(result[task_empty.id]).to eq(0)
    end

    it 'loads documents in a single query regardless of the number of tasks' do
      ids = [task_half, task_none, task_empty].map(&:id)
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?('documents') }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        described_class.percent_done_by_task_id(ids)
      end

      expect(queries.size).to eq(1)
    end
  end
end
