# Deals with whatever is still buffered when a recipient changes their
# email_frequency preference. Called after the new preference has been saved.
#
# NotificationDigestJob only visits users whose *current* preference is
# throttled, so without this, rows buffered under the old setting would sit in
# the table forever and never be sent.
class ResolveBufferedNotifications
  def self.call(recipient_email:, new_frequency:)
    recipient_email = recipient_email.to_s.strip
    return if recipient_email.blank?

    case new_frequency.to_s
    when NotificationService::UNLIMITED
      # "stop holding my mail" -> flush the buffer as one last digest. Not a
      # periodic send, so no minimum interval applies.
      SendNotificationDigest.call(recipient_email: recipient_email, min_interval: nil)
    when NotificationService::NONE
      # "send me nothing" -> discard. Flushing would mail someone who has just
      # asked for silence.
      PendingNotification.where(recipient_email: recipient_email).delete_all
    else
      # Still throttled, just on the other period: the next scheduled run picks
      # the buffer up as it is.
      nil
    end
  end
end
