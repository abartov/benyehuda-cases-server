# Creates ScanFolder records for folders in the raw ingestion area that lack one.
# Only folders that directly hold scans get a record; their ancestor folder
# names become FolderTags on it. If the immediate parent folder is named only
# with a four-digit year, that year also becomes the copyright expiration year.
class SyncScanFolders
  YEAR_FOLDER = /\A\d{4}\z/

  def self.expiration_year_from(parent_name)
    parent_name.to_i if parent_name.to_s.strip.match?(YEAR_FOLDER)
  end

  # Returns the number of ScanFolders created.
  def self.call
    created = 0
    ScanStorage.discover_folders.each do |name, ancestors|
      next if ScanFolder.exists?(name: name)

      ScanFolder.transaction do
        sf = ScanFolder.create!(name: name, status: 'raw',
                                copyright_expiration_year: expiration_year_from(ancestors.last))
        sf.tag_names = ancestors
      end
      created += 1
    rescue ActiveRecord::RecordNotUnique
      next # created concurrently (e.g. by a web upload)
    rescue ActiveRecord::RecordInvalid => e
      raise unless e.record.errors.of_kind?(:name, :taken) && e.record.errors.size == 1

      next # same, caught by the uniqueness validation
    end
    Rails.logger.info("SyncScanFolders: created #{created} scan folders")
    created
  end
end
