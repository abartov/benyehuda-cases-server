# Deletes the stored files of ScanFolders completed over a year ago, keeping the record.
class ArchiveOldScanFolders
  def self.call(older_than: 1.year)
    count = 0
    ScanFolder.where(status: 'complete').where('completed_at < ?', older_than.ago).find_each do |sf|
      sf.archive!
      count += 1
    end
    Rails.logger.info("ArchiveOldScanFolders: archived #{count} scan folders")
    count
  end
end
