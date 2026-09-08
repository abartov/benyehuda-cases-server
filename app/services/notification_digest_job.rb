# Scheduled entry point: drains every recipient currently on the given
# frequency into one digest each.
#
# This app has no ActiveJob backend, so this is a plain class invoked from
# lib/tasks/notification_digests.rake, which config/initializers/scheduler.rb
# runs via rufus-scheduler.
class NotificationDigestJob
  # Deliberately shorter than the nominal period. Ordinary scheduler jitter -- a
  # run firing a few seconds earlier than the previous one did -- would
  # otherwise make sent_within? true and swallow a whole period's digest.
  MIN_INTERVALS = { 'daily' => 23.hours, 'weekly' => 6.days }.freeze

  # Returns the number of digests actually delivered.
  def self.perform(frequency)
    frequency = frequency.to_s
    raise ArgumentError, "unknown digest frequency: #{frequency.inspect}" unless MIN_INTERVALS.key?(frequency)

    min_interval = MIN_INTERVALS[frequency]
    recipients_for(frequency).count do |email|
      SendNotificationDigest.call(recipient_email: email, min_interval: min_interval)
    end
  end

  # Selection is by *current* preference, which is why ResolveBufferedNotifications
  # has to deal with rows buffered under a preference the user has since changed:
  # this query would never visit them again.
  def self.recipients_for(frequency)
    PendingNotification
      .where(recipient_email: User.where(email_frequency: frequency).select(:email))
      .distinct
      .pluck(:recipient_email)
  end
end
