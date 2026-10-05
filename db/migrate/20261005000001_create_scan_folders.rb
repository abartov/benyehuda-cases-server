class CreateScanFolders < ActiveRecord::Migration[6.1]
  def change
    create_table :scan_folders do |t|
      t.string :name, null: false # S3 path relative to the raw ingestion root
      t.string :status, null: false, default: 'raw'
      t.string :title
      t.string :author
      t.text :comment
      t.integer :copyright_expiration_year
      t.integer :task_id
      t.datetime :completed_at
      t.timestamps
    end
    add_index :scan_folders, :name, unique: true
    add_index :scan_folders, :status
    add_index :scan_folders, :task_id

    create_table :folder_tags do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :folder_tags, :name, unique: true

    create_table :folder_taggings do |t|
      t.references :scan_folder, null: false, index: false
      t.references :folder_tag, null: false
      t.timestamps
    end
    add_index :folder_taggings, %i[scan_folder_id folder_tag_id], unique: true
  end
end
