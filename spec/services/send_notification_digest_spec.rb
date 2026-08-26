require 'rails_helper'

RSpec.describe SendNotificationDigest do
  let(:recipient) { create(:user, email_frequency: 'daily') }

  before { ActionMailer::Base.deliveries.clear }

  def buffer(args = [recipient], mailer_method: :volnteer_welcome)
    PendingNotification.buffer!(recipient_email: recipient.email, mailer_class: Notification,
                               mailer_method: mailer_method, args: args)
  end

  def drain(min_interval: 23.hours)
    described_class.call(recipient_email: recipient.email, min_interval: min_interval)
  end

  it 'sends exactly one email containing every buffered notification' do
    3.times { buffer([create(:user)]) }

    expect(drain).to be true
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(ActionMailer::Base.deliveries.last.to).to eq([recipient.email])
    expect(PendingNotification.for_recipient(recipient.email)).to be_empty
  end

  it 'records a watermark so a second run in the same period sends nothing' do
    buffer
    drain
    buffer

    expect(drain).to be false
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(PendingNotification.for_recipient(recipient.email).count).to eq(1)
  end

  it 'sends again once the minimum interval has elapsed' do
    buffer
    drain
    DigestDelivery.record!(recipient.email, 25.hours.ago)
    buffer

    expect(drain).to be true
    expect(ActionMailer::Base.deliveries.size).to eq(2)
  end

  it 'ignores the watermark when no minimum interval is given' do
    buffer
    drain
    buffer

    expect(drain(min_interval: nil)).to be true
    expect(ActionMailer::Base.deliveries.size).to eq(2)
  end

  it 'drains notifications regardless of age, rather than waiting a whole period' do
    buffer.update_column(:created_at, 5.seconds.ago)

    expect(drain).to be true
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'does nothing at all when there is nothing buffered' do
    expect(drain).to be false
    expect(ActionMailer::Base.deliveries).to be_empty
    expect(DigestDelivery.where(recipient_email: recipient.email)).to be_empty
  end

  it 'does not touch another recipient\'s buffer' do
    other = create(:user, email_frequency: 'daily')
    PendingNotification.buffer!(recipient_email: other.email, mailer_class: Notification,
                                mailer_method: :volnteer_welcome, args: [other])
    buffer

    drain

    expect(PendingNotification.for_recipient(other.email).count).to eq(1)
  end

  describe 'unresolvable rows' do
    it 'drops them and still delivers the recipient\'s other notifications' do
      doomed = create(:user)
      broken = buffer([doomed])
      good = buffer([recipient])
      doomed.destroy

      expect(drain).to be true
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(PendingNotification.where(id: [broken.id, good.id])).to be_empty
    end

    it 'sends nothing when every buffered row is unresolvable, but clears them out' do
      doomed = create(:user)
      broken = buffer([doomed])
      doomed.destroy

      expect(drain).to be false
      expect(ActionMailer::Base.deliveries).to be_empty
      expect(PendingNotification.where(id: broken.id)).to be_empty
      expect(DigestDelivery.where(recipient_email: recipient.email)).to be_empty
    end
  end

  describe 'when delivery fails' do
    before do
      allow(Notification).to receive(:notification_digest).and_raise(Net::SMTPServerBusy, 'nope')
    end

    it 'leaves the rows buffered so the next run retries them' do
      buffer

      expect(drain).to be false
      expect(PendingNotification.for_recipient(recipient.email).count).to eq(1)
    end

    it 'does not record a watermark, which would suppress the retry' do
      buffer
      drain

      expect(DigestDelivery.where(recipient_email: recipient.email)).to be_empty
    end
  end

  describe 'item cap' do
    before { stub_const('Notification::DIGEST_ITEM_LIMIT', 2) }

    it 'renders up to the cap and reports the rest as a count' do
      3.times { buffer([create(:user)]) }

      drain

      body = ActionMailer::Base.deliveries.last.body.decoded
      expect(body).to include(I18n.t('notification_digest.omitted', count: 1, locale: :he))
    end

    it 'still deletes the capped-out rows, since the count is the record of them' do
      3.times { buffer([create(:user)]) }

      drain

      expect(PendingNotification.for_recipient(recipient.email)).to be_empty
    end
  end
end
