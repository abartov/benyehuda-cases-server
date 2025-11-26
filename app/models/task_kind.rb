class TaskKind < ActiveRecord::Base
  has_many :tasks, :dependent => :destroy, :foreign_key => 'kind_id'
  validates :name, :presence => true, :uniqueness => true
  before_destroy :validate_task_existance #, :on => :destroy

#  attr_accessible :name

  protected

  def validate_task_existance
    if tasks.size > 0
      errors.add(:base, I18n.t('gettext.there_are_existing_tasks_that_use_kind', name: name))
      return false
    end
  end
end
