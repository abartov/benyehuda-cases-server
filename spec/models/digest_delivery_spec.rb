require 'rails_helper'

RSpec.describe DigestDelivery, type: :model do
  let(:email) { 'someone@example.com' }

  describe '.sent_within?' do
    it 'is false when the address has never received a digest' do
      expect(described_class.sent_within?(email, 23.hours)).to be false
    end

    it 'is true within the interval and false once it has elapsed' do
      described_class.record!(email, 10.hours.ago)

      expect(described_class.sent_within?(email, 23.hours)).to be true
      expect(described_class.sent_within?(email, 5.hours)).to be false
    end

    it 'is false when no interval is given, so a one-off flush is never skipped' do
      described_class.record!(email, 1.minute.ago)

      expect(described_class.sent_within?(email, nil)).to be false
    end

    it 'does not confuse one recipient with another' do
      described_class.record!(email, 1.hour.ago)

      expect(described_class.sent_within?('elsewhere@example.com', 23.hours)).to be false
    end
  end

  describe '.record!' do
    it 'creates the watermark row on first use' do
      expect { described_class.record!(email) }.to change(described_class, :count).by(1)
    end

    it 'updates the existing row rather than adding a second one' do
      described_class.record!(email, 2.days.ago)

      expect { described_class.record!(email) }.not_to change(described_class, :count)
      expect(described_class.find_by(recipient_email: email).last_digest_sent_at).to be > 1.minute.ago
    end
  end

  it 'refuses a second row for the same address at the database level' do
    described_class.record!(email)

    expect { described_class.new(recipient_email: email, last_digest_sent_at: Time.zone.now).save!(validate: false) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end
end
