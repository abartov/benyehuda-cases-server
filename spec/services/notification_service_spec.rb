require 'rails_helper'

RSpec.describe NotificationService do
  before { ActionMailer::Base.deliveries.clear }

  describe '.call' do
    context 'when the recipient is on the default (unlimited) frequency' do
      let(:user) { create(:user) }

      it 'delivers the notification immediately' do
        expect {
          described_class.call(mailer_method: :volnteer_welcome, recipient_email: user.email, args: [user])
        }.to change { ActionMailer::Base.deliveries.size }.by(1)

        expect(ActionMailer::Base.deliveries.last.to).to eq([user.email])
      end

      it 'buffers nothing' do
        expect {
          described_class.call(mailer_method: :volnteer_welcome, recipient_email: user.email, args: [user])
        }.not_to change(PendingNotification, :count)
      end
    end

    context 'when the recipient has no account at all' do
      it 'defaults to unlimited and delivers' do
        user = create(:user)

        expect {
          described_class.call(mailer_method: :volnteer_welcome, recipient_email: 'stranger@example.com', args: [user])
        }.to change { ActionMailer::Base.deliveries.size }.by(1)

        expect(ActionMailer::Base.deliveries.last.to).to eq(['stranger@example.com'])
      end
    end

    %w[daily weekly].each do |frequency|
      context "when the recipient is on #{frequency}" do
        let(:user) { create(:user, email_frequency: frequency) }

        it 'buffers the notification instead of sending it' do
          expect {
            described_class.call(mailer_method: :volnteer_welcome, recipient_email: user.email, args: [user])
          }.to change(PendingNotification, :count).by(1)

          expect(ActionMailer::Base.deliveries).to be_empty
          expect(PendingNotification.last.notification_type).to eq('Notification#volnteer_welcome')
        end
      end
    end

    context 'when the recipient asked for no email at all' do
      let(:user) { create(:user, email_frequency: 'none') }

      it 'neither sends nor buffers' do
        expect {
          described_class.call(mailer_method: :volnteer_welcome, recipient_email: user.email, args: [user])
        }.not_to change(PendingNotification, :count)

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    it 'does nothing for a blank address' do
      user = create(:user)

      expect {
        described_class.call(mailer_method: :volnteer_welcome, recipient_email: '  ', args: [user])
      }.not_to change(PendingNotification, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'narrows the envelope to the one address whose preference was checked' do
      assignee = create(:user)
      editor = create(:user)
      task = create(:task, assignee: assignee, editor: editor)
      ActionMailer::Base.deliveries.clear

      # Notification#task_idle addresses assignee *and* editor for itself.
      described_class.call(mailer_method: :task_idle, recipient_email: editor.email,
                           args: [task, assignee, editor])

      expect(ActionMailer::Base.deliveries.last.to).to eq([editor.email])
    end

    it 'does not mail a throttled recipient who was named inside another recipient\'s notification' do
      assignee = create(:user, email_frequency: 'daily')
      editor = create(:user)
      task = create(:task, assignee: assignee, editor: editor)
      ActionMailer::Base.deliveries.clear

      described_class.call(mailer_method: :task_idle, recipient_email: editor.email,
                           args: [task, assignee, editor])

      expect(ActionMailer::Base.deliveries.flat_map(&:to)).to eq([editor.email])
    end
  end

  describe '.frequency_for' do
    it 'returns the stored preference' do
      user = create(:user, email_frequency: 'weekly')

      expect(described_class.frequency_for(user.email)).to eq('weekly')
    end

    it 'falls back to unlimited for an unknown address' do
      expect(described_class.frequency_for('nobody@example.com')).to eq('unlimited')
    end

    it 'falls back to unlimited for a value that is not a recognised frequency' do
      user = create(:user)
      user.update_column(:email_frequency, 'hourly')

      expect(described_class.frequency_for(user.email)).to eq('unlimited')
    end
  end
end
