require 'fileutils'

class ScanStorage
  # Local-disk stand-in for S3, used in development and test.
  class DiskBackend
    def self.root
      @root ||= Rails.root.join('tmp', 'scan_storage', Rails.env)
    end

    def root
      self.class.root
    end

    def path_for(key)
      path = root.join(key).cleanpath
      raise ArgumentError, 'invalid key' unless path.to_s.start_with?("#{root}/")

      path
    end

    def list(prefix)
      base = root.to_s + '/'
      Dir.glob(root.join('**', '*').to_s).select { |f| File.file?(f) }.filter_map do |f|
        key = f.delete_prefix(base)
        next unless key.start_with?(prefix)

        { key: key, size: File.size(f), last_modified: File.mtime(f) }
      end
    end

    def put(key, io, _content_type = nil)
      path = path_for(key)
      FileUtils.mkdir_p(path.dirname)
      io.rewind if io.respond_to?(:rewind)
      File.binwrite(path, io.read)
    end

    def get(key)
      File.binread(path_for(key))
    end

    def delete(key)
      FileUtils.rm_f(path_for(key))
    end

    def delete_prefix(prefix)
      list(prefix).each { |o| delete(o[:key]) }
    end

    def url(key, _expires_in)
      rel = key.delete_prefix("#{ScanStorage::ROOT}/")
      folder, filename = File.split(rel)
      Rails.application.routes.url_helpers.file_scan_folders_path(folder: folder, filename: filename,
                                                                  t: File.mtime(path_for(key)).to_i)
    end
  end
end
