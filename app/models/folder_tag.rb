class FolderTag < ApplicationRecord
  has_many :folder_taggings, dependent: :destroy
  has_many :scan_folders, through: :folder_taggings

  validates :name, presence: true, uniqueness: true

  before_validation { self.name = name.to_s.strip }
end
