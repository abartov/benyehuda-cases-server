require 'rails_helper'

RSpec.describe PurgeStaleBufferedNotifications do
  let(:user) { create(:user, email_frequency: 'weekly') }

  def buffer(age)
    PendingNotification.buffer!(recipient_email: user.email, mailer_class: Notification,
                                mailer_method: :volnteer_welcome, args: [user])
                       .tap { |pending| pending.update_column(:created_at, age.ago) }
  end

  it 'deletes rows older than twice the longest digest period' do
    stale = buffer(PendingNotification::MAX_AGE + 1.day)

    expect(described_class.call).to eq(1)
    expect(PendingNotification.where(id: stale.id)).to be_empty
  end

  it 'keeps anything a live schedule would still deliver' do
    fresh = buffer(PendingNotification::MAX_AGE - 1.day)

    expect(described_class.call).to eq(0)
    expect(PendingNotification.where(id: fresh.id)).to be_present
  end

  it 'sweeps rows left behind by a destroyed account, which no digest run would ever visit' do
    orphan_owner = create(:user, email_frequency: 'weekly')
    PendingNotification.buffer!(recipient_email: orphan_owner.email, mailer_class: Notification,
                                mailer_method: :volnteer_welcome, args: [user])
                       .update_column(:created_at, 1.month.ago)
    orphan_owner.destroy

    expect { described_class.call }.to change(PendingNotification, :count).by(-1)
  end
end
