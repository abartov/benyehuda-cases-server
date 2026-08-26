# Drains one recipient's buffered notifications into a single digest email.
#
# Shared by the scheduled run (NotificationDigestJob) and by the one-off flush
# ResolveBufferedNotifications performs when someone turns throttling off.
#
# The governing trade-off throughout: a duplicate digest is an acceptable
# failure, a dropped notification is not. Every rescue below follows from that
# asymmetry -- inverting any of them trades lost mail for tidier code.
class SendNotificationDigest
  # min_interval nil means "send regardless of when the last digest went out",
  # used by the one-off flush, which is not a periodic send.
  def self.call(recipient_email:, min_interval:)
    new(recipient_email, min_interval).call
  end

  def initialize(recipient_email, min_interval)
    @recipient_email = recipient_email.to_s.strip
    @min_interval = min_interval
  end

  def call
    return false if @recipient_email.blank?

    if DigestDelivery.sent_within?(@recipient_email, @min_interval)
      Rails.logger.info("SendNotificationDigest: #{@recipient_email} already received a digest this period")
      return false
    end

    # No age filter here. An earlier version of this in the reference app
    # filtered to rows older than the period, on the theory that that was the
    # throttle. It is not -- the watermark above is -- and the filter bought
    # nothing but a full extra period of delivery latency for every notification.
    pending = PendingNotification.for_recipient(@recipient_email).to_a
    return false if pending.empty?

    renderable, unresolvable = pending.partition(&:resolvable?)
    PendingNotification.where(id: unresolvable.map(&:id)).delete_all if unresolvable.any?
    return false if renderable.empty?

    # Deliberately outside the transaction below: the send is the part that can
    # fail slowly and out of our control.
    deliver(renderable)

    # Rows may never be deleted without the watermark recording why, so both
    # happen together. A crash between the send and this transaction re-sends
    # the digest on the next run: a duplicate, i.e. the failure direction we chose.
    PendingNotification.transaction do
      PendingNotification.where(id: renderable.map(&:id)).delete_all
      DigestDelivery.record!(@recipient_email)
    end
    true
  rescue ActiveRecord::RecordNotUnique
    # Two runs raced this recipient and both passed sent_within?. Both had
    # already delivered by the time either reached here, so the worst case is a
    # duplicate digest and nothing is dropped unsent. Not worth paging anyone.
    Rails.logger.info("SendNotificationDigest: lost watermark race for #{@recipient_email}; digest may be duplicated")
    false
  rescue StandardError => e
    # Leave the rows buffered so the next run retries them. Do not "clean this
    # up" into a delete-always: that silently loses the recipient's notifications.
    Rails.logger.error("SendNotificationDigest: failed for #{@recipient_email}: #{e.class}: #{e.message}")
    false
  end

  private

  def deliver(notifications)
    items = PendingNotification.collapse(notifications)
    shown = items.first(Notification::DIGEST_ITEM_LIMIT)
    omitted = count_of(items) - count_of(shown)

    I18n.with_locale(:he) do
      Notification.notification_digest(@recipient_email, shown, omitted).deliver
    end
  end

  def count_of(items)
    items.sum { |(_notification, occurrences)| occurrences }
  end
end
