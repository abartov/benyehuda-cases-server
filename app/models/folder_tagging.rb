class FolderTagging < ApplicationRecord
  belongs_to :scan_folder
  belongs_to :folder_tag

  validates :folder_tag_id, uniqueness: { scope: :scan_folder_id }
end
