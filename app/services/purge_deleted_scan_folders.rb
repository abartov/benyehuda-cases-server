# Physically deletes ScanFolders soft-deleted over two years ago, along with their stored files.
class PurgeDeletedScanFolders
  def self.call(older_than: ScanFolder::PURGE_AFTER)
    count = 0
    ScanFolder.purgeable(older_than).find_each do |sf|
      sf.purge!
      count += 1
    end
    Rails.logger.info("PurgeDeletedScanFolders: purged #{count} scan folders")
    count
  end
end
