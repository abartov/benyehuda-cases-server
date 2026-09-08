require 'rails_helper'

RSpec.describe 'User email frequency preference', type: :request do
  let(:user) { create(:user, :active_user, email_frequency: 'daily') }

  before do
    post '/user_sessions', params: { user_session: { email: user.email, password: 'qweqwe' } }
    PendingNotification.buffer!(recipient_email: user.email, mailer_class: Notification,
                                mailer_method: :volnteer_welcome, args: [user])
    ActionMailer::Base.deliveries.clear
  end

  def change_frequency_to(frequency)
    put user_path(user), params: { user: { email_frequency: frequency } }
  end

  it 'stores the new preference' do
    change_frequency_to('weekly')

    expect(user.reload.email_frequency).to eq('weekly')
  end

  it 'flushes the buffer as a final digest when throttling is turned off' do
    change_frequency_to('unlimited')

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(PendingNotification.for_recipient(user.email)).to be_empty
  end

  it 'discards the buffer when the user asks for no email' do
    change_frequency_to('none')

    expect(ActionMailer::Base.deliveries).to be_empty
    expect(PendingNotification.for_recipient(user.email)).to be_empty
  end

  it 'leaves the buffer alone when the preference did not change' do
    expect(ResolveBufferedNotifications).not_to receive(:call)

    change_frequency_to('daily')

    expect(PendingNotification.for_recipient(user.email).count).to eq(1)
  end

  it 'rejects a frequency the app does not support' do
    change_frequency_to('hourly')

    expect(user.reload.email_frequency).to eq('daily')
  end
end
