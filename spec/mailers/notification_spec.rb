require 'rails_helper'

RSpec.describe Notification, type: :mailer do
  describe '#anniversary_greeting' do
    let(:sender) { create(:user, :editor, name: 'Editor Name') }
    let(:message) { 'תודה על תרומתך!' }

    context 'when user has been volunteering for 1 year' do
      let(:user) { create(:user, :volunteer, name: 'Volunteer Name', created_at: 1.year.ago - 1.day) }

      it 'uses singular form in subject line' do
        mail = Notification.anniversary_greeting(user, sender, message)

        expect(mail.subject).to eq('שנה של התנדבות בפרויקט בן־יהודה!')
        expect(mail.subject).not_to include('{:one=>')
        expect(mail.subject).not_to include(':other=>')
      end
    end

    context 'when user has been volunteering for 3 years' do
      let(:user) { create(:user, :volunteer, name: 'Volunteer Name', created_at: 3.years.ago - 1.day) }

      it 'uses plural form in subject line with correct year count' do
        mail = Notification.anniversary_greeting(user, sender, message)

        expect(mail.subject).to eq('3 שנים של התנדבות בפרויקט בן־יהודה!')
        expect(mail.subject).not_to include('{:one=>')
        expect(mail.subject).not_to include(':other=>')
      end
    end

    context 'when user has been volunteering for 5 years' do
      let(:user) { create(:user, :volunteer, name: 'Volunteer Name', created_at: 5.years.ago - 1.day) }

      it 'uses plural form in subject line with correct year count' do
        mail = Notification.anniversary_greeting(user, sender, message)

        expect(mail.subject).to eq('5 שנים של התנדבות בפרויקט בן־יהודה!')
        expect(mail.subject).not_to include('{:one=>')
        expect(mail.subject).not_to include(':other=>')
      end
    end
  end
end
