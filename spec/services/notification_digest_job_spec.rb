require 'rails_helper'

RSpec.describe NotificationDigestJob do
  before { ActionMailer::Base.deliveries.clear }

  def buffer_for(user)
    PendingNotification.buffer!(recipient_email: user.email, mailer_class: Notification,
                                mailer_method: :volnteer_welcome, args: [user])
  end

  describe '.perform' do
    it 'rejects a frequency it has no interval for' do
      expect { described_class.perform('hourly') }.to raise_error(ArgumentError, /hourly/)
      expect { described_class.perform(nil) }.to raise_error(ArgumentError)
    end

    it 'digests only the recipients on the requested frequency' do
      daily = create(:user, email_frequency: 'daily')
      weekly = create(:user, email_frequency: 'weekly')
      [daily, weekly].each { |u| buffer_for(u) }

      expect(described_class.perform('daily')).to eq(1)
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to eq([daily.email])
      expect(PendingNotification.for_recipient(weekly.email).count).to eq(1)
    end

    it 'leaves unthrottled and opted-out recipients alone' do
      unlimited = create(:user)
      silent = create(:user, email_frequency: 'none')
      # Buffered directly, bypassing the gate, to prove selection is by preference.
      [unlimited, silent].each { |u| buffer_for(u) }

      expect(described_class.perform('daily')).to eq(0)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'sends one email per recipient, not one per notification' do
      user = create(:user, email_frequency: 'daily')
      3.times { buffer_for(user) }

      expect(described_class.perform('daily')).to eq(1)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it 'sends nothing on a second run in the same period' do
      user = create(:user, email_frequency: 'daily')
      buffer_for(user)
      described_class.perform('daily')
      buffer_for(user)

      expect(described_class.perform('daily')).to eq(0)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it 'uses an interval shorter than the nominal period, so scheduler jitter cannot swallow a digest' do
      expect(described_class::MIN_INTERVALS['daily']).to be < 1.day
      expect(described_class::MIN_INTERVALS['weekly']).to be < 1.week
    end
  end

  describe '.recipients_for' do
    it 'only returns addresses that actually have something buffered' do
      create(:user, email_frequency: 'daily')
      with_buffer = create(:user, email_frequency: 'daily')
      buffer_for(with_buffer)

      expect(described_class.recipients_for('daily')).to eq([with_buffer.email])
    end
  end
end
