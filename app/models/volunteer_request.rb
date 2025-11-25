class VolunteerRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :approver, class_name: 'User'

  validates :user_id, presence: true

  accepts_nested_attributes_for :user, allow_destroy: false

  scope :pending, -> { where('volunteer_requests.approved_at is NULL') }
  scope :by_request_time, -> { order('volunteer_requests.created_at') }
  scope :with_user, -> { includes(:user) }

  # CustomProperties removed - no specific properties used
  # include CustomProperties
  # has_many_custom_properties :request # task_properties

  def approve!(approver_user)
    self.approver = approver_user
    self.approved_at = Time.zone.now
    save!
    user.is_volunteer = true
    user.set_volunteer_preferences(preferences) if preferences.present?
    user.save!
  end
end
