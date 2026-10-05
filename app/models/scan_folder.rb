class ScanFolder < ApplicationRecord
  STATUSES = %w[raw approved postponed complete archived].freeze
  YEARS_AFTER_DEATH = 71
  MAX_FILE_SIZE = 50.megabytes # Document's attachment limit
  CONVERTIBLE_STATUSES = %w[approved postponed].freeze

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

  # Files too large to attach to a Document.
  def oversized_files
    files.select { |f| f[:size] >= MAX_FILE_SIZE }
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

  class InvalidState < StandardError; end

  # Both transitions are only valid from 'raw'. Re-checked under a row lock, so a stale form (or a
  # concurrent conversion/archive) can't drag a completed folder back to an earlier status.
  def approve!
    with_lock do
      raise InvalidState, I18n.t('scans.invalid_state') unless status == 'raw'

      update!(status: 'approved')
    end
  end

  def postpone!(expiration_year:, tag_names: [])
    with_lock do
      raise InvalidState, I18n.t('scans.invalid_state') unless status == 'raw'

      self.tag_names = folder_tags.map(&:name) + Array(tag_names) if tag_names.present?
      update!(status: 'postponed', copyright_expiration_year: expiration_year.presence)
    end
  end

  def mark_complete!(task)
    update!(status: 'complete', task_id: task.id, completed_at: Time.zone.now)
  end

  def archive!
    ScanStorage.delete_direct_files(name)
    update!(status: 'archived')
  end
end
