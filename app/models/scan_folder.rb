class ScanFolder < ApplicationRecord
  # 'uploading' reserves the name while a web upload is still writing files; it has no actions.
  STATUSES = %w[uploading raw approved postponed complete archived deleted].freeze
  YEARS_AFTER_DEATH = 71
  MAX_FILE_SIZE = 50.megabytes # Document's attachment limit
  PURGE_AFTER = 2.years
  CONVERTIBLE_STATUSES = %w[approved postponed].freeze

  belongs_to :task, optional: true
  has_many :folder_taggings, dependent: :destroy
  has_many :folder_tags, through: :folder_taggings

  validates :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  # Soft-deleted folders show only when explicitly asked for.
  scope :with_status, ->(status) { status.present? ? where(status: status) : where.not(status: 'deleted') }
  scope :expiring_in, ->(year) { year.present? ? where(copyright_expiration_year: year.to_i) : all }
  scope :purgeable, ->(older_than = PURGE_AFTER) { where(status: 'deleted').where('deleted_at < ?', older_than.ago) }
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

  # Same composition as the name of the Task created from the folder.
  def self.task_name(title, author)
    "#{title.to_s.strip} / #{author.to_s.strip}"
  end

  # Title and author when the folder has a title, else the raw folder name.
  def display_name
    title.present? ? self.class.task_name(title, author) : name
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

  # Soft delete: files stay in storage until PurgeDeletedScanFolders removes them.
  def soft_delete!
    with_lock do
      raise InvalidState, I18n.t('scans.invalid_state') if %w[uploading deleted].include?(status)

      update!(status: 'deleted', deleted_at: Time.zone.now)
    end
  end

  # Physically removes the record and its direct files (nested folders are separate ScanFolders).
  def purge!
    ScanStorage.delete_direct_files(name)
    destroy!
  end

  def archive!
    ScanStorage.delete_direct_files(name)
    update!(status: 'archived')
  end
end
