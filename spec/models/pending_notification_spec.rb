require 'rails_helper'

RSpec.describe PendingNotification, type: :model do
  let(:recipient) { create(:user) }

  def buffer(mailer_method, args)
    described_class.buffer!(recipient_email: recipient.email, mailer_class: Notification,
                            mailer_method: mailer_method, args: args)
  end

  describe '.buffer!' do
    it 'records the mailer, the method and a resolvable reference to record arguments' do
      pending = buffer(:volnteer_welcome, [recipient])

      expect(pending.notification_type).to eq('Notification#volnteer_welcome')
      expect(pending.mailer_class).to eq(Notification)
      expect(pending.mailer_method).to eq('volnteer_welcome')
      expect(pending.deserialized_args).to eq([recipient])
    end

    it 'round-trips ActiveRecord arguments as records rather than flattening them to hashes' do
      other = create(:user)
      pending = described_class.find(buffer(:volunteer_returned_from_break, [recipient, other]).id)

      args = pending.deserialized_args
      expect(args.map(&:class)).to eq([User, User])
      expect(args.map(&:id)).to eq([recipient.id, other.id])
    end

    it 'raises at the call site when an argument cannot be serialized' do
      expect { buffer(:volnteer_welcome, [Object.new]) }
        .to raise_error(ActiveJob::SerializationError)
    end
  end

  describe '#resolvable?' do
    it 'is true for a notification whose arguments still exist' do
      expect(buffer(:volnteer_welcome, [recipient]).resolvable?).to be true
    end

    it 'is false once a referenced record has been deleted' do
      subject_user = create(:user)
      pending = described_class.find(buffer(:volnteer_welcome, [subject_user]).id)
      subject_user.destroy

      expect(pending.resolvable?).to be false
    end

    it 'is false when the mailer method no longer exists' do
      pending = buffer(:volnteer_welcome, [recipient])
      pending.update_column(:notification_data,
                            pending.notification_data.sub('volnteer_welcome', 'method_removed_in_a_refactor'))

      expect(described_class.find(pending.id).resolvable?).to be false
    end

    it 'is false when the mailer class no longer exists' do
      pending = buffer(:volnteer_welcome, [recipient])
      pending.update_column(:notification_data, pending.notification_data.sub('"Notification"', '"DeletedMailer"'))

      expect(described_class.find(pending.id).resolvable?).to be false
    end
  end

  describe '.collapse' do
    it 'folds exact duplicates into [notification, occurrences] pairs, preserving order' do
      first = buffer(:volnteer_welcome, [recipient])
      buffer(:volnteer_welcome, [recipient])
      second = buffer(:tasks_added_to_site, [recipient])

      collapsed = described_class.collapse(described_class.for_recipient(recipient.email).to_a)

      expect(collapsed.map { |(n, count)| [n.id, count] }).to eq([[first.id, 2], [second.id, 1]])
    end

    it 'does not fold notifications of the same type with different payloads' do
      other = create(:user)
      buffer(:volnteer_welcome, [recipient])
      buffer(:volnteer_welcome, [other])

      collapsed = described_class.collapse(described_class.for_recipient(recipient.email).to_a)

      expect(collapsed.map(&:last)).to eq([1, 1])
    end
  end
end
