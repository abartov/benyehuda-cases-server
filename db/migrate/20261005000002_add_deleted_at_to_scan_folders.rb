class AddDeletedAtToScanFolders < ActiveRecord::Migration[6.1]
  def change
    add_column :scan_folders, :deleted_at, :datetime
    add_index :scan_folders, :copyright_expiration_year
  end
end
