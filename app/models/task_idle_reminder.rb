class TaskIdleReminder < ApplicationRecord
  belongs_to :task
  belongs_to :user

  validates :task_id, presence: true
  validates :user_id, presence: true
  validates :sent_at, presence: true

  # Find the last reminder sent for a specific task and user combination
  def self.last_reminder_for(task_id, user_id)
    where(task_id: task_id, user_id: user_id).order(sent_at: :desc).first
  end

  # Check if a reminder was sent to this user for this task within the given period
  def self.sent_within?(task_id, user_id, period)
    last_reminder = last_reminder_for(task_id, user_id)
    last_reminder && last_reminder.sent_at > period.ago
  end
end
