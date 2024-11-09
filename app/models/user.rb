include ThinkingSphinx::Scopes
class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.perishable_token_valid_for = 2.weeks
    c.transition_from_crypto_providers = [Authlogic::CryptoProviders::Sha512]
    c.crypto_provider = Authlogic::CryptoProviders::SCrypt
    #c.crypto_provider = Authlogic::CryptoProviders::Sha512 # addressing a breaking change in Authlogic 3.4.0, sigh (June 2015)
  end
  include Astrails::Auth::Model
  validates :email, uniqueness: { case_sensitive: false, if: :will_save_change_to_email? }
#  attr_accessible :name, :password, :password_confirmation, :notify_on_comments, :notify_on_status, :volunteer_kind_id, :email, :zehut, :avatar

  has_gravatar
  has_attached_file :avatar, :styles => { :thumb => "50x50>", :medium => "100x100>" },
    :storage        => :s3,
    :bucket         => GlobalPreference.get(:s3_bucket),
    :path =>        "users/:id/avatars/:style/:filename",
    :s3_protocol => :https,
    s3_region: 'us-east-1',
    :s3_credentials => {
      :access_key_id     => GlobalPreference.get(:s3_key) || "junk",
      :secret_access_key => GlobalPreference.get(:s3_secret) || "junk",
    }
  validates_attachment :avatar, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"] }

  has_many :audits
  def self.style_to_size(style)
    case style
    when :thumb
      50
    when :medium
      100
    else
      50
    end
  end

  has_many :assignment_histories, :dependent => :destroy

  validates :name, :presence => true

  scope :volunteers, -> {where("is_volunteer = 1 AND activated_at IS NOT NULL AND disabled_at IS NULL")}
  scope :all_volunteers, -> {where("(users.is_volunteer = 1 OR is_editor = 1 OR is_admin = 1) AND activated_at IS NOT NULL AND disabled_at IS NULL")}

  scope :editors, -> {where("is_editor = 1 AND activated_at IS NOT NULL AND disabled_at IS NULL")}
  scope :all_editors, -> {where("(is_editor = 1 OR is_admin = 1) AND activated_at IS NOT NULL AND disabled_at IS NULL")}

  scope :admins, -> {where(:is_admin => true)}

  scope :enabled, -> {where("users.disabled_at IS NULL")}
  scope :not_on_break, -> {where("users.is_volunteer = 1 AND users.on_break = 0 AND users.disabled_at IS NULL AND users.activated_at IS NOT NULL")}
  scope :active, -> {where("users.activated_at IS NOT NULL")}
  scope :not_activated, -> {where("users.activated_at is NULL")}
  scope :active_first, -> {order("users.current_login_at DESC")}
  scope :by_id, -> {order("users.id")}
  scope :by_last_login, -> {order("users.current_login_at DESC")}

  scope :waiting_for_tasks, ->{where("users.task_requested_at IS NOT NULL").order('users.task_requested_at DESC')}

  has_one :volunteer_request
  has_many :confirmed_volunteer_requests, :class_name => "VolunteerRequest", :foreign_key => :approver_id
  # has_many :volunteers_approved, :through => :volunteer_confirmations, :source => :user

  include CustomProperties
  has_many_custom_properties :user # user_properties
  has_many_custom_properties :volunteer # volunteer_properties
  has_many_custom_properties :editor #editor_properties

  has_many :created_tasks, :class_name => "Task", :foreign_key => "creator_id"
  has_many :editing_tasks, ->{order("tasks.updated_at desc")}, :class_name => "Task", :foreign_key => "editor_id"
  has_many :assigned_tasks, :class_name => "Task", :foreign_key => "assignee_id" #, :order => "tasks.updated_at"

  has_many :comments
  has_many :search_settings
  belongs_to :kind, :class_name => "VolunteerKind", :foreign_key => :volunteer_kind_id
  has_and_belongs_to_many :teams, :join_table => :team_memberships
  has_many :team_memberships
  #FIXME add validation and validate_kind?
  # validates :volunteer_kind_id, :presence => true, :if => :validate_kind?, :on => :update

  before_update :handle_volunteer_kind, :request_task_on_volunteering
  after_update :welcome_on_volunteering

  sphinx_scope(:sp_enabled) { {:where => "disabled_at is NULL"}}
  sphinx_scope(:sp_active_first) { {:order => "current_login_at DESC"}}
  sphinx_scope(:sp_all) { {}}

  def has_no_credentials?
    # self.crypted_password.blank?
    self.crypted_password.blank? && !activated_at.blank?
  end

  def wants_to_be_notified_of?(type)
    case type.to_sym
    when :comments
      notify_on_comments?
    when :state
      notify_on_status?
    else
      nil
    end
  end

  def allow_email_change?(force = false)
    force || activated_at.nil? || new_record?
  end

  def email_recipient
    email
#    addr = GlobalPreference.get(:email_override)
#    addr = email if addr.blank?
#    "#{name.gsub('"','')} <#{addr}>"
  end

  def disabled?
    !disabled_at.blank?
  end

  def might_become_volunteer?
    !is_volunteer? && !admin_or_editor? && volunteer_request.blank?
  end

  def public_roles
    @public_roles ||= [].tap do |res|
      res << "admin" if is_admin?
      res << "editor" if is_editor?
      res << "volunteer" if is_volunteer?
    end
  end

  def deliver_activation_instructions_with_db_update!
    update_attribute(:activation_email_sent_at, Time.zone.now)
    deliver_activation_instructions_without_db_update!
  end
  alias_method :deliver_activation_instructions_without_db_update!, :deliver_activation_instructions!
  alias_method :deliver_activation_instructions!, :deliver_activation_instructions_with_db_update!
  #alias_method_chain :deliver_activation_instructions!, :db_update

  def admin_or_editor?
    try(:is_admin?) || try(:is_editor?)
  end

  def set_task_requested
    self.task_requested_at = Time.zone.now
    self.on_break = false
    self
  end

  def clear_task_requested!
    self.task_requested_at = nil
    save!
  end
  def vol_active?
    vol_active_in_last_n_months?(6)
  end
  def vol_active_in_last_n_months?(n)
    self.assignment_histories.with_task.where().order('updated_at desc').each {|h|
      if h.updated_at > n.months.ago
        return true
      end
    }
    return false
  end
  def self.vols_active_in_last_n_months(n)
    User.not_on_break.distinct.joins(:audits).where('audits.created_at > ?', n.months.ago)
  end
  def self.vols_inactive_in_last_n_months(n)
    User.not_on_break.distinct.joins(:audits).where.not('audits.created_at > ?', n.months.ago)
  end
  def self.vols_newer_than(t)
    return User.all_volunteers.where(:activated_at => t..Date.today)
  end
  def self.vols_created_between(fromdate, todate)
    return User.all_volunteers.where(:activated_at => fromdate..todate)
  end
  def to_csv
    return "#{name.gsub('"','')}, #{email}, #{current_login_at.to_s}, #{activated_at.to_s}, #{assignment_histories.count}, https://tasks.benyehuda.org/profiles/#{id}"
  end

  protected

  def request_task_on_volunteering
    set_task_requested if is_volunteer_changed? && is_volunteer?
  end

  def welcome_on_volunteering
    Notification.volnteer_welcome(self).deliver if is_volunteer_changed? && is_volunteer?
  end

  def handle_volunteer_kind
    self.volunteer_kind_id = nil if is_volunteer_changed? && !is_volunteer?
  end
end
