require 'rails_helper'

RSpec.describe 'scan folder scheduled jobs' do
  describe SyncScanFolders do
    it 'creates missing folders with parent tags and is idempotent' do
      existing = create(:scan_folder, name: 'solo')
      allow(ScanStorage).to receive(:discover_folders)
        .and_return([['עם עובד/A', ['עם עובד']], ['עם עובד/B', ['עם עובד']], ['solo', []]])
      expect { described_class.call }.to change(ScanFolder, :count).by(2)
      a = ScanFolder.find_by(name: 'עם עובד/A')
      expect(a.status).to eq 'raw'
      expect(a.folder_tags.map(&:name)).to eq ['עם עובד']
      expect(FolderTag.where(name: 'עם עובד').count).to eq 1
      expect(existing.reload.folder_tags).to be_empty
      expect { described_class.call }.not_to change(ScanFolder, :count)
    end
  end

  describe ArchiveOldScanFolders do
    it 'archives only folders completed over a year ago' do
      old = create(:scan_folder, status: 'complete', completed_at: 13.months.ago)
      recent = create(:scan_folder, status: 'complete', completed_at: 2.months.ago)
      expect(ScanStorage).to receive(:delete_direct_files).with(old.name)
      described_class.call
      expect(old.reload.status).to eq 'archived'
      expect(recent.reload.status).to eq 'complete'
    end
  end

  describe ApproveExpiringScanFolders do
    it 'approves postponed folders expiring next year only' do
      today = Date.new(2027, 1, 1)
      due = create(:scan_folder, status: 'postponed', copyright_expiration_year: 2028)
      later = create(:scan_folder, status: 'postponed', copyright_expiration_year: 2030)
      raw = create(:scan_folder, status: 'raw', copyright_expiration_year: 2028)
      described_class.call(today: today)
      expect([due, later, raw].map { |f| f.reload.status }).to eq %w[approved postponed raw]
    end
  end
end
