# One row per recipient address, recording when that address last received a
# digest.
#
# This table -- specifically the unique index on recipient_email -- is the
# actual "one email per period" guarantee. Without it the promise would rest
# entirely on the scheduler firing exactly once per period, which a manual
# re-run, a redeploy that re-fires the recurring entry, a second app instance or
# a post-outage backfill each break, every one of them mailing every throttled
# recipient a second full digest.
class DigestDelivery < ApplicationRecord
  validates :recipient_email, presence: true, uniqueness: true
  validates :last_digest_sent_at, presence: true

  def self.sent_within?(recipient_email, interval)
    return false if interval.nil?

    where(recipient_email: recipient_email).where('last_digest_sent_at > ?', interval.ago).exists?
  end

  # Raises ActiveRecord::RecordNotUnique if another run inserted the row for
  # this address in between; the caller treats that as a lost race, not an error.
  def self.record!(recipient_email, at = Time.zone.now)
    row = find_or_initialize_by(recipient_email: recipient_email)
    row.last_digest_sent_at = at
    row.save!
    row
  end
end
