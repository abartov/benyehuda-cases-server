# Sweeps buffered notifications that no live schedule would ever deliver.
#
# Because pending_notifications has no foreign key (it is keyed on an address,
# not a user id), a row can outlive the preference that created it and even the
# account itself: a destroyed user leaves its rows behind, and nothing else
# would ever remove them.
class PurgeStaleBufferedNotifications
  # Returns the number of rows deleted.
  def self.call(max_age: PendingNotification::MAX_AGE)
    deleted = PendingNotification.where('created_at < ?', max_age.ago).delete_all
    Rails.logger.info("PurgeStaleBufferedNotifications: deleted #{deleted} rows older than #{max_age.inspect}")
    deleted
  end
end
