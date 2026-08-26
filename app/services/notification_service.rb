# The single send-or-buffer gate for notification email.
#
# EVERY Notification mailer send in the app must go through here. A call site
# that invokes the mailer directly is unthrottled, and the recipient's
# email_frequency preference silently does not apply to it.
#
# Transactional mail (activation instructions, password reset -- see
# Astrails::Auth::Mailer) deliberately does *not* pass through this gate and is
# never throttled or suppressed.
class NotificationService
  UNLIMITED = 'unlimited'.freeze
  NONE = 'none'.freeze
  THROTTLED_FREQUENCIES = %w[daily weekly].freeze
  FREQUENCIES = ([UNLIMITED] + THROTTLED_FREQUENCIES + [NONE]).freeze

  class << self
    # Sends the mail immediately, buffers it for a digest, or drops it,
    # according to the recipient's preference. Addresses with no user account
    # default to 'unlimited', so notifications to non-users behave as before.
    def call(mailer_method:, recipient_email:, args: [], mailer_class: Notification)
      recipient_email = recipient_email.to_s.strip
      return nil if recipient_email.blank?

      case frequency_for(recipient_email)
      when NONE
        Rails.logger.info("NotificationService: suppressed #{mailer_class}##{mailer_method} for #{recipient_email}")
        nil
      when *THROTTLED_FREQUENCIES
        PendingNotification.buffer!(recipient_email: recipient_email, mailer_class: mailer_class,
                                    mailer_method: mailer_method, args: args)
      else
        deliver_now(mailer_class, mailer_method, recipient_email, args)
      end
    end

    def frequency_for(recipient_email)
      frequency = User.where(email: recipient_email).pick(:email_frequency)
      FREQUENCIES.include?(frequency) ? frequency : UNLIMITED
    end

    private

    def deliver_now(mailer_class, mailer_method, recipient_email, args)
      message = I18n.with_locale(:he) { mailer_class.public_send(mailer_method, *args).message }
      # The gate owns the envelope: whatever recipients the mailer method
      # computed for itself, this delivery goes to exactly the one address whose
      # preference was just checked. Without this, a mailer that fans out
      # internally (Notification#task_idle mails assignee *and* editor) would
      # reach addresses that never passed through the gate.
      message.to = [recipient_email]
      message.deliver
      message
    end
  end
end
