namespace :scans do
  desc 'Create ScanFolders for new folders in the raw ingestion area'
  task sync: :environment do
    SyncScanFolders.call
  end

  desc 'Archive ScanFolders completed over a year ago'
  task archive_old: :environment do
    ArchiveOldScanFolders.call
  end

  desc 'Approve postponed ScanFolders whose copyright expires next year'
  task approve_expiring: :environment do
    ApproveExpiringScanFolders.call
  end
end
