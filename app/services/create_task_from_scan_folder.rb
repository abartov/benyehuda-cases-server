require 'stringio'

# Creates a typing (הקלדה) Task from a ScanFolder, attaching the folder's files as
# Documents in natural filename order, then marks the folder complete.
class CreateTaskFromScanFolder
  class Error < StandardError; end

  def self.call(scan_folder, user:, title:, author:)
    raise Error, I18n.t('scans.title_author_required') if title.blank? || author.blank?

    task = Task.new(name: "#{title.strip} / #{author.strip}", kind_id: :הקלדה, creator_id: user.id,
                    editor_id: user.id)
    task.save!
    begin
      scan_folder.files.each do |f|
        data = ScanStorage.read(scan_folder.name, f[:name])
        io = StringIO.new(data)
        io.define_singleton_method(:original_filename) { f[:name] }
        io.define_singleton_method(:content_type) { Marcel::MimeType.for(name: f[:name]) }
        Document.create!(task: task, user: user, file: io)
      end
    rescue StandardError
      task.destroy
      raise
    end
    scan_folder.update!(title: title, author: author)
    scan_folder.mark_complete!(task)
    task
  end
end
