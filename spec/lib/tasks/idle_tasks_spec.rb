require 'rails_helper'
require 'rake'

RSpec.describe 'tasks:send_idle_notifications rake task', type: :task do
  before(:all) do
    Rake.application.rake_require 'tasks/idle_tasks'
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task['tasks:send_idle_notifications'] }

  before(:each) do
    task.reenable
    ENV.delete('is_staging')
    ENV.delete('DRY_RUN')
  end

  after(:each) do
    ENV.delete('is_staging')
    ENV.delete('DRY_RUN')
  end

  describe 'staging mode (is_staging=true)' do
    before { allow_any_instance_of(Task).to receive(:delayed_notify_on_changes) }

    let!(:assignee) { create(:user, :volunteer, :active_user) }
    let!(:editor)   { create(:user, :editor, :active_user) }
    let!(:idle_task) do
      t = create(:assigned_task, assignee: assignee, editor: editor)
      t.update_column(:updated_at, 5.months.ago)
      t
    end

    before { ENV['is_staging'] = 'true' }

    it 'does not call Notification.task_idle' do
      expect(Notification).not_to receive(:task_idle)
      task.invoke
    end

    it 'does not call Notification.editor_idle_tasks_report' do
      expect(Notification).not_to receive(:editor_idle_tasks_report)
      task.invoke
    end

    it 'does not create TaskIdleReminder records' do
      expect { task.invoke }.not_to change(TaskIdleReminder, :count)
    end

    it 'prints a STAGING MODE banner' do
      expect { task.invoke }.to output(/STAGING MODE/).to_stdout
    end

    it 'is also suppressed when is_staging has mixed case or whitespace' do
      ENV['is_staging'] = ' True '
      expect(Notification).not_to receive(:task_idle)
      task.invoke
    end
  end
end
