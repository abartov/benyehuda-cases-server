require 'mini_magick'

# Thin wrapper over the S3 raw-ingestion area. Every key lives under ROOT.
class ScanStorage
  ROOT = 'raw_scans'.freeze
  SCAN_EXTS = %w[jpg jpeg png tif tiff pdf].freeze
  IMAGE_EXTS = %w[jpg jpeg png tif tiff].freeze

  class << self
    # Dev and test use local disk; set SCAN_STORAGE=s3 (or =disk) to override.
    def backend
      @backend ||= begin
        kind = ENV['SCAN_STORAGE'].presence || (Rails.env.production? ? 's3' : 'disk')
        kind == 's3' ? ScanStorage::S3Backend.new : ScanStorage::DiskBackend.new
      end
    end

    attr_writer :backend

    # Kept for specs that stub the AWS client.
    def client=(client)
      @backend = client && ScanStorage::S3Backend.new(client)
    end

    def folder_prefix(name)
      "#{ROOT}/#{name}/"
    end

    def key_for(folder, filename)
      "#{folder_prefix(folder)}#{filename}"
    end

    def scan_file?(key)
      SCAN_EXTS.include?(File.extname(key).delete('.').downcase)
    end

    def image_file?(key)
      IMAGE_EXTS.include?(File.extname(key).delete('.').downcase)
    end

    # Every object under the root (or under a given prefix).
    def list_objects(prefix = "#{ROOT}/")
      backend.list(prefix)
    end

    # Direct (non-recursive) scan files of a folder, naturally sorted by file name.
    def list_files(folder)
      prefix = folder_prefix(folder)
      list_objects(prefix).filter_map do |o|
        rel = o[:key].delete_prefix(prefix)
        next if rel.empty? || rel.include?('/') || !scan_file?(rel)

        o.merge(name: rel)
      end.sort_by { |f| natural_key(f[:name]) }
    end

    # Folders (names relative to ROOT) directly holding scan files, each paired with
    # its ancestor folder names: [['עם עובד/A', ['עם עובד']], ...]
    def discover_folders
      folders = list_objects.filter_map do |o|
        rel = o[:key].delete_prefix("#{ROOT}/")
        next unless rel.include?('/') && scan_file?(rel)

        File.dirname(rel)
      end.uniq
      folders.map { |f| [f, f.split('/')[0...-1]] }
    end

    def folder_exists?(folder)
      list_objects(folder_prefix(folder)).any?
    end

    def upload(folder, filename, io, content_type: nil)
      backend.put(key_for(folder, filename), io, content_type)
    end

    def delete_file(folder, filename)
      backend.delete(key_for(folder, filename))
    end

    def delete_folder(folder)
      backend.delete_prefix(folder_prefix(folder))
    end

    def read(folder, filename)
      backend.get(key_for(folder, filename))
    end

    # A URL the browser can fetch the file from.
    def presigned_url(folder, filename, expires_in: 3600)
      backend.url(key_for(folder, filename), expires_in)
    end

    # Absolute path of a disk-backed file (nil for S3); used to serve it.
    def disk_path(folder, filename)
      backend.is_a?(ScanStorage::DiskBackend) ? backend.path_for(key_for(folder, filename)) : nil
    end

    # Rotates an image clockwise by +degrees+ (default 90), overwriting the original.
    def rotate(folder, filename, degrees = 90)
      transform(folder, filename) { |img| img.rotate(degrees.to_i) }
    end

    # Crops to the rectangle (pixels in the original image's coordinates), overwriting the original.
    def crop(folder, filename, x:, y:, width:, height:)
      transform(folder, filename) do |img|
        img.combine_options do |c|
          c.crop "#{width.to_i}x#{height.to_i}+#{x.to_i}+#{y.to_i}"
          c << '+repage'
        end
      end
    end

    # Sorts "file2.jpg" before "file11.jpg": digit runs compare numerically.
    def natural_key(str)
      str.to_s.downcase.scan(/\d+|\D+/).map { |p| p =~ /\A\d+\z/ ? [0, p.to_i, ''] : [1, 0, p] }
    end

    private

    def transform(folder, filename)
      raise ArgumentError, 'not an image' unless image_file?(filename)

      image = MiniMagick::Image.read(read(folder, filename))
      yield image
      backend.put(key_for(folder, filename), StringIO.new(image.to_blob), Marcel::MimeType.for(name: filename))
    end
  end
end
