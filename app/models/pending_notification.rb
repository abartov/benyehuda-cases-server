# A notification that was buffered instead of sent, awaiting inclusion in a
# digest email.
#
# Rows are written by NotificationService for recipients whose email_frequency
# is throttled, and deleted by SendNotificationDigest once the digest carrying
# them has been delivered. Rows are never updated, hence created_at only.
class PendingNotification < ApplicationRecord
  # Twice the longest digest period, so anything a live schedule would still
  # deliver is safe from the sweeper. See PurgeStaleBufferedNotifications.
  MAX_AGE = 2.weeks

  validates :recipient_email, presence: true
  validates :notification_type, presence: true

  scope :for_recipient, ->(email) { where(recipient_email: email).order(:created_at, :id) }

  # Arguments are frequently ActiveRecord objects. Plain JSON would flatten
  # them into hashes the mailer can no longer render, so we use ActiveJob's own
  # argument serializer: it round-trips records as GlobalIDs, and it raises here
  # at the call site if something unserializable is passed, rather than silently
  # producing a notification that fails to render days later.
  def self.buffer!(recipient_email:, mailer_class:, mailer_method:, args:)
    create!(
      recipient_email: recipient_email,
      notification_type: "#{mailer_class.name}##{mailer_method}",
      notification_data: {
        'mailer_class' => mailer_class.name,
        'mailer_method' => mailer_method.to_s,
        'args' => ActiveJob::Arguments.serialize(args)
      }.to_json
    )
  end

  def data
    @data ||= JSON.parse(notification_data.presence || '{}')
  rescue JSON::ParserError
    @data = {}
  end

  def mailer_class
    @mailer_class ||= data['mailer_class'].to_s.safe_constantize
  end

  def mailer_method
    data['mailer_method']
  end

  def deserialized_args
    @deserialized_args ||= ActiveJob::Arguments.deserialize(data['args'] || [])
  end

  # False when this row can never be rendered again -- typically because a
  # record it refers to has since been deleted. Without this check one dangling
  # reference would raise on every digest run and block that recipient's other
  # notifications forever.
  def resolvable?
    return unresolvable("unknown mailer class #{data['mailer_class'].inspect}") if mailer_class.nil?
    unless mailer_class.action_methods.include?(mailer_method.to_s)
      return unresolvable("unknown mailer method #{mailer_method.inspect}")
    end

    deserialized_args
    true
  rescue StandardError => e
    unresolvable("#{e.class}: #{e.message}")
  end

  # Folds *exact* duplicates (same notification_type and same payload) into
  # [notification, occurrences] pairs, preserving first-seen order. Grouping on
  # type alone would be lossy: two different tasks changing state are both
  # task_state_changed but are two different things to tell the recipient.
  def self.collapse(notifications)
    notifications.group_by { |n| [n.notification_type, n.notification_data] }
                 .map { |_key, group| [group.first, group.size] }
  end

  private

  def unresolvable(reason)
    Rails.logger.warn("PendingNotification #{id} (#{notification_type}) is unresolvable: #{reason}")
    false
  end
end
