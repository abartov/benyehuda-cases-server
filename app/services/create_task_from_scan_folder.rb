require 'stringio'

# Creates a typing (הקלדה) Task from a ScanFolder, attaching the folder's files as
# Documents in natural filename order, then marks the folder complete.
class CreateTaskFromScanFolder
  class Error < StandardError; end

  def self.call(scan_folder, user:, title:, author:)
    raise Error, I18n.t('scans.title_author_required') if title.blank? || author.blank?

    task = nil
    scan_folder.with_lock do
      raise Error, I18n.t('scans.already_converted') if scan_folder.task_id.present?
      raise Error, I18n.t('scans.not_convertible') unless ScanFolder::CONVERTIBLE_STATUSES.include?(scan_folder.status)

      oversized = scan_folder.oversized_files
      if oversized.any?
        raise Error, I18n.t('scans.task_files_too_large', files: oversized.map { |f| f[:name] }.join(', '),
                                                      max: ScanFolder::MAX_FILE_SIZE / 1.megabyte)
      end

      task = build_task(scan_folder, user, title, author)
      scan_folder.update!(title: title, author: author)
      scan_folder.mark_complete!(task)
    end
    task
  end

  def self.build_task(scan_folder, user, title, author)
    task = Task.new(name: "#{title.strip} / #{author.strip}", kind_id: :הקלדה, creator_id: user.id,
                    editor_id: user.id)
    task.save!
    begin
      scan_folder.files.each do |f|
        io = StringIO.new(ScanStorage.read(scan_folder.name, f[:name]))
        io.define_singleton_method(:original_filename) { f[:name] }
        io.define_singleton_method(:content_type) { Marcel::MimeType.for(name: f[:name]) }
        Document.create!(task: task, user: user, file: io)
      end
    rescue StandardError
      task.destroy
      raise
    end
    task
  end
  private_class_method :build_task
end
