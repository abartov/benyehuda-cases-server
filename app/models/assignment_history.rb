class AssignmentHistory < ActiveRecord::Base
  belongs_to :user
  belongs_to :task

  validates :user_id, :task_id, :role, :presence => true

#  attr_accessible :user_id, :task_id, :role

  scope :recent, lambda { |l| limit(l) }
  scope :with_task, ->{includes(:task)}
  scope :rev_order, ->{order("id DESC")}

  ROLES = {
    "assignee" => 'gettext.assignee',
    "creator" => 'gettext.creator',
    "editor" => 'gettext.editor'
  }

  def role_txt
    I18n.t(ROLES[role])
  end
end
