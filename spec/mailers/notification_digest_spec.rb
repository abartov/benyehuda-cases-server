require 'rails_helper'

RSpec.describe Notification, type: :mailer do
  describe '#notification_digest' do
    let(:recipient) { create(:user, name: 'Digest Recipient', email: 'digest@example.com', email_frequency: 'daily') }

    def buffer(args = [recipient], mailer_method: :volnteer_welcome)
      PendingNotification.buffer!(recipient_email: recipient.email, mailer_class: Notification,
                                  mailer_method: mailer_method, args: args)
    end

    def digest(items, omitted = 0)
      I18n.with_locale(:he) { described_class.notification_digest(recipient.email, items, omitted) }
    end

    # Mail hands bodies back with CRLF line endings; the individual mailers
    # render LF, so compare on normalised text.
    def unix_body(mail)
      mail.body.decoded.gsub("\r\n", "\n")
    end

    it 'embeds the body each notification would have had on its own' do
      mail = digest([[buffer, 1]])

      individual = described_class.volnteer_welcome(recipient).body.decoded.gsub("\r\n", "\n").strip
      expect(unix_body(mail)).to include(individual)
      expect(mail.to).to eq([recipient.email])
    end

    it 'counts every notification in the subject, including capped-out ones' do
      mail = digest([[buffer, 2]], 3)

      expect(mail.subject).to eq(I18n.t('notification_digest.subject', count: 5, locale: :he))
    end

    it 'notes how many times a repeated notification occurred' do
      mail = digest([[buffer, 4]])

      expect(mail.body.decoded).to include(I18n.t('notification_digest.occurrences', count: 4, locale: :he))
    end

    it 'says nothing about occurrences for a notification that happened once' do
      mail = digest([[buffer, 1]])

      expect(mail.body.decoded).not_to include(I18n.t('notification_digest.occurrences', count: 1, locale: :he))
    end

    it 'reports the omitted count when items were capped' do
      mail = digest([[buffer, 1]], 7)

      expect(mail.body.decoded).to include(I18n.t('notification_digest.omitted', count: 7, locale: :he))
    end

    it 'omits the omitted-count line when nothing was capped' do
      mail = digest([[buffer, 1]])

      expect(mail.body.decoded).not_to include(I18n.t('notification_digest.omitted', count: 1, locale: :he))
    end

    it 'substitutes a placeholder for one unrenderable item instead of losing the whole digest' do
      good = buffer
      bad = buffer([create(:user)])
      allow_any_instance_of(PendingNotification).to receive(:deserialized_args) do |pending|
        raise 'boom' if pending.id == bad.id

        [recipient]
      end

      mail = digest([[good, 1], [bad, 1]])

      expect(unix_body(mail)).to include(I18n.t('notification_digest.render_failed', locale: :he))
      expect(unix_body(mail)).to include(described_class.volnteer_welcome(recipient).body.decoded.gsub("\r\n", "\n").strip)
    end

    it 'links a registered recipient to their own preferences page' do
      mail = digest([[buffer, 1]])

      expect(mail.body.decoded).to include("/users/#{recipient.id}/edit")
    end

    it 'invites an unregistered recipient to sign up instead' do
      pending = PendingNotification.buffer!(recipient_email: 'stranger@example.com', mailer_class: described_class,
                                            mailer_method: :volnteer_welcome, args: [recipient])
      mail = I18n.with_locale(:he) { described_class.notification_digest('stranger@example.com', [[pending, 1]], 0) }

      expect(mail.body.decoded).to include('/signup')
    end

    it 'caps at a limit low enough to survive a provider\'s size checks' do
      expect(described_class::DIGEST_ITEM_LIMIT).to be_between(1, 100)
    end
  end
end
