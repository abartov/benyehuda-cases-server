class ScanFolder < ApplicationRecord
  STATUSES = %w[raw approved postponed complete archived].freeze
  YEARS_AFTER_DEATH = 71

  belongs_to :task, optional: true
  has_many :folder_taggings, dependent: :destroy
  has_many :folder_tags, through: :folder_taggings

  validates :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :with_status, ->(status) { status.present? ? where(status: status) : all }
  scope :name_like, lambda { |q|
    q.present? ? where('scan_folders.name LIKE ?', "%#{sanitize_sql_like(q)}%") : all
  }
  # ANDed: only folders carrying *every* given tag.
  scope :tagged_with_all, lambda { |tag_ids|
    ids = Array(tag_ids).reject(&:blank?).map(&:to_i).uniq
    next all if ids.empty?

    where(id: FolderTagging.where(folder_tag_id: ids).group(:scan_folder_id)
                           .having('COUNT(DISTINCT folder_tag_id) = ?', ids.size).select(:scan_folder_id))
  }

  def self.expiration_from_death_year(year)
    year.to_i + YEARS_AFTER_DEATH if year.present?
  end

  def prefix
    ScanStorage.folder_prefix(name)
  end

  def files
    @files ||= ScanStorage.list_files(name)
  end

  def file_count
    files.size
  end

  def total_size
    files.sum { |f| f[:size] }
  end

  def tag_names=(names)
    self.folder_tags = Array(names).map(&:to_s).map(&:strip).reject(&:blank?).uniq.map do |n|
      FolderTag.find_or_create_by!(name: n)
    end
  end

  def approve!
    update!(status: 'approved')
  end

  def postpone!(expiration_year:, tag_names: [])
    transaction do
      self.tag_names = folder_tags.map(&:name) + Array(tag_names) if tag_names.present?
      update!(status: 'postponed', copyright_expiration_year: expiration_year.presence)
    end
  end

  def mark_complete!(task)
    update!(status: 'complete', task_id: task.id, completed_at: Time.zone.now)
  end

  def archive!
    ScanStorage.delete_folder(name)
    update!(status: 'archived')
  end
end
