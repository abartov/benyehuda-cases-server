require 'rails_helper'

RSpec.describe ResolveBufferedNotifications do
  let(:user) { create(:user, email_frequency: 'daily') }

  before do
    ActionMailer::Base.deliveries.clear
    PendingNotification.buffer!(recipient_email: user.email, mailer_class: Notification,
                                mailer_method: :volnteer_welcome, args: [user])
  end

  it 'flushes the buffer as one last digest when throttling is turned off' do
    described_class.call(recipient_email: user.email, new_frequency: 'unlimited')

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(PendingNotification.for_recipient(user.email)).to be_empty
  end

  it 'flushes even if a digest already went out in this period' do
    DigestDelivery.record!(user.email, 1.minute.ago)

    described_class.call(recipient_email: user.email, new_frequency: 'unlimited')

    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'discards the buffer when the recipient asks for silence' do
    described_class.call(recipient_email: user.email, new_frequency: 'none')

    expect(ActionMailer::Base.deliveries).to be_empty
    expect(PendingNotification.for_recipient(user.email)).to be_empty
  end

  it 'leaves the buffer for the next run when switching between throttled periods' do
    described_class.call(recipient_email: user.email, new_frequency: 'weekly')

    expect(ActionMailer::Base.deliveries).to be_empty
    expect(PendingNotification.for_recipient(user.email).count).to eq(1)
  end

  it 'does nothing for a blank address' do
    expect { described_class.call(recipient_email: nil, new_frequency: 'none') }
      .not_to change(PendingNotification, :count)
  end
end
