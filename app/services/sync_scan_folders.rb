# Creates ScanFolder records for folders in the raw ingestion area that lack one.
# Only folders that directly hold scans get a record; their ancestor folder
# names become FolderTags on it.
class SyncScanFolders
  # Returns the number of ScanFolders created.
  def self.call
    created = 0
    ScanStorage.discover_folders.each do |name, ancestors|
      next if ScanFolder.exists?(name: name)

      ScanFolder.transaction do
        sf = ScanFolder.create!(name: name, status: 'raw')
        sf.tag_names = ancestors
      end
      created += 1
    rescue ActiveRecord::RecordNotUnique
      next # created concurrently (e.g. by a web upload)
    end
    Rails.logger.info("SyncScanFolders: created #{created} scan folders")
    created
  end
end
