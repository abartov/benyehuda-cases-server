class ScanFoldersController < ApplicationController
  before_action :require_admin
  before_action :load_scan_folder, except: %i[index new create file]
  helper_method :display_url

  PER_PAGE = 25

  def index
    @statuses = ScanFolder::STATUSES
    @all_tags = FolderTag.order(:name)
    @tag_ids = Array(params[:tag_ids]).reject(&:blank?)
    @scan_folders = ScanFolder.with_status(params[:status]).name_like(params[:q]).tagged_with_all(@tag_ids)
                              .includes(:folder_tags).order(created_at: :desc)
                              .paginate(page: params[:page], per_page: PER_PAGE)
  end

  # Modal content: thumbnails plus title/author form.
  def show
    @files = @scan_folder.files
    render partial: 'scan_folders/modal', locals: { scan_folder: @scan_folder, files: @files }
  end

  def new; end

  def create
    name = params[:name].to_s.strip
    files = Array(params[:files]).select { |f| f.respond_to?(:original_filename) }
    return upload_error(:name_required) if name.blank? || name.include?('/') || name.start_with?('.')
    return upload_error(:files_required) if files.empty?
    return upload_error(:not_a_scan) unless files.all? { |f| ScanStorage.scan_file?(f.original_filename) }
    return upload_error(:files_too_large) if files.any? { |f| f.size >= ScanFolder::MAX_FILE_SIZE }
    return upload_error(:name_taken) if ScanFolder.exists?(name: name) || ScanStorage.folder_exists?(name)

    begin
      files.each do |f|
        ScanStorage.upload(name, File.basename(f.original_filename), f.tempfile, content_type: f.content_type)
      end
      ScanFolder.create!(name: name, comment: params[:comment].presence)
    rescue StandardError
      # The folder didn't exist before this attempt, so everything under it is ours: don't leave a
      # partial upload for scheduled discovery to register.
      ScanStorage.delete_folder(name)
      raise
    end
    flash[:notice] = I18n.t('scans.folder_created')
    redirect_to scan_folders_path
  end

  def file
    path = ScanStorage.disk_path(params[:folder].to_s, File.basename(params[:filename].to_s))
    return head :not_found unless path && File.file?(path)

    send_file path, disposition: :inline
  end

  def update
    @scan_folder.update!(params.permit(:title, :author, :comment))
    render json: { ok: true, message: I18n.t('scans.saved') }
  end

  def approve
    @scan_folder.approve! if @scan_folder.status == 'raw'
    redirect_back fallback_location: scan_folders_path
  end

  def postpone
    year = params[:expiration_year].presence ||
           ScanFolder.expiration_from_death_year(params[:year_of_death])
    tags = Array(params[:tag_ids]).reject(&:blank?).map { |id| FolderTag.find(id).name } +
           params[:new_tags].to_s.split(/[,،]/)
    @scan_folder.postpone!(expiration_year: year, tag_names: tags)
    redirect_back fallback_location: scan_folders_path
  end

  def create_task
    task = CreateTaskFromScanFolder.call(@scan_folder, user: current_user, title: params[:title],
                                                       author: params[:author])
    flash[:notice] = I18n.t('scans.task_created')
    redirect_to task_path(task)
  rescue CreateTaskFromScanFolder::Error, ActiveRecord::RecordInvalid => e
    flash[:error] = e.message
    redirect_back fallback_location: scan_folders_path
  end

  # Browser-displayable JPEG of a (TIFF) scan, same pixel dimensions as the original.
  def preview
    send_data ScanStorage.preview(@scan_folder.name, file_name), type: 'image/jpeg', disposition: :inline
  end

  def delete_file
    ScanStorage.delete_file(@scan_folder.name, file_name)
    head :no_content
  end

  def rotate_file
    ScanStorage.rotate(@scan_folder.name, file_name)
    render json: { url: display_url(@scan_folder, file_name) }
  end

  def crop_file
    ScanStorage.crop(@scan_folder.name, file_name, x: params[:x], y: params[:y], width: params[:width],
                                                    height: params[:height])
    render json: { url: display_url(@scan_folder, file_name) }
  end

  private

  # URL for an <img>/Cropper: TIFFs go through the JPEG preview, as browsers can't display them.
  # Signed S3 URLs are returned untouched (altering the query string would invalidate the signature).
  def display_url(scan_folder, filename)
    if ScanStorage.tiff_file?(filename)
      preview_scan_folder_path(scan_folder, filename: filename, t: (Time.now.to_f * 1000).to_i)
    else
      ScanStorage.presigned_url(scan_folder.name, filename)
    end
  end

  def load_scan_folder
    @scan_folder = ScanFolder.find(params[:id])
  end

  # Only ever a bare file name: never lets a request escape the folder.
  def file_name
    File.basename(params.require(:filename).to_s)
  end

  def upload_error(key)
    flash.now[:error] = I18n.t("scans.#{key}")
    render :new
  end
end
