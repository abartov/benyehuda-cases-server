require 'rails_helper'

# End-to-end coverage of the throttle from a real trigger (a comment on a task)
# through the buffer and out as a digest, rather than through the gate directly.
RSpec.describe 'Notification throttling', type: :model do
  let(:editor) { create(:user, :editor, :active_user) }
  let(:volunteer) { create(:user, :volunteer, :active_user, email_frequency: frequency) }
  let(:task) { create(:task, assignee: volunteer, editor: editor) }

  before do
    task
    ActionMailer::Base.deliveries.clear
  end

  def comment_three_times
    3.times { |i| create(:comment, task: task, user: editor, message: "comment number #{i}") }
  end

  context 'for a recipient on the daily digest' do
    let(:frequency) { 'daily' }

    it 'buffers every notification instead of mailing them one by one' do
      comment_three_times

      expect(ActionMailer::Base.deliveries.flat_map(&:to)).not_to include(volunteer.email)
      expect(PendingNotification.for_recipient(volunteer.email).count).to eq(3)
    end

    it 'delivers exactly one email containing all of them at the next run' do
      comment_three_times

      NotificationDigestJob.perform('daily')

      digests = ActionMailer::Base.deliveries.select { |mail| mail.to == [volunteer.email] }
      expect(digests.size).to eq(1)
      body = digests.first.body.decoded
      3.times { |i| expect(body).to include("comment number #{i}") }
    end

    it 'sends nothing on a second run in the same period' do
      comment_three_times
      NotificationDigestJob.perform('daily')
      ActionMailer::Base.deliveries.clear

      NotificationDigestJob.perform('daily')

      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  context 'for a recipient on the default frequency' do
    let(:frequency) { 'unlimited' }

    it 'mails each notification immediately, unchanged' do
      comment_three_times

      expect(ActionMailer::Base.deliveries.count { |mail| mail.to == [volunteer.email] }).to eq(3)
      expect(PendingNotification.for_recipient(volunteer.email)).to be_empty
    end
  end

  context 'for a recipient who asked for no email' do
    let(:frequency) { 'none' }

    it 'neither mails nor buffers anything' do
      comment_three_times

      expect(ActionMailer::Base.deliveries.flat_map(&:to)).not_to include(volunteer.email)
      expect(PendingNotification.for_recipient(volunteer.email)).to be_empty
    end
  end
end
