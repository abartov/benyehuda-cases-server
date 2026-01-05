class DocumentsController < InheritedResources::Base
  belongs_to :task
  before_action :require_task_participant_or_editor, only: %i[new create show]
  before_action :require_owner, only: :destroy
  actions :new, :create, :destroy, :show
  layout nil

  # new - shouldn't be used

  # show
  def show
    render layout: false
  end

  def workaround_download
    document = Document.find(params[:document])
    if (require_user && document.task.participant?(current_user)) || (require_user && current_user.try(:is_admin?))
      response = HTTParty.get(document.file.url)
      send_data response.body, type: document.file_content_type, disposition: 'inline'
    else
      flash[:error] = _('Only participant can see this page')
      redirect_to task_path(task)
    end
  end

  def proxy_image
    document = Document.find(params[:id])
    if (require_user && document.task.participant?(current_user)) || (require_user && current_user.try(:is_admin?))
      http_response = HTTParty.get(document.file.url)
      # Set CORS headers to allow canvas manipulation
      response.headers['Access-Control-Allow-Origin'] = '*'
      content_type = document.file_content_type || 'image/jpeg'
      send_data http_response.body, type: content_type, disposition: 'inline'
    else
      head :forbidden
    end
  end

  def download_cropped
    document = Document.find(params[:id])
    if (require_user && document.task.participant?(current_user)) || (require_user && current_user.try(:is_admin?))
      # Receive base64-encoded image data from client
      image_data = params[:image_data]

      # Extract the base64 data (remove data:image/jpeg;base64, prefix)
      base64_data = image_data.split(',')[1]
      binary_data = Base64.decode64(base64_data)

      # Determine content type and extension from data URL prefix
      content_type = image_data.match(/data:(image\/[^;]+)/)[1]
      extension = content_type.split('/')[1]
      extension = 'jpg' if extension == 'jpeg'

      # Generate filename
      filename = params[:filename] || "cropped_#{document.id}.#{extension}"

      send_data binary_data,
                type: content_type,
                disposition: 'attachment',
                filename: filename
    else
      head :forbidden
    end
  end

  # create
  def create
    #    @document = task.prepare_document(current_user, params.permit(document: :file)['document'])
    @document = task.prepare_document(current_user, params['upload_documents'])

    create! do |success, failure|
      success.js do
        render json: { files: [@document.to_fileupload(:file, :original)],
                       li_item: render_to_string(partial: 'documents/document',
                                                 locals: { document: @document }) }
      end
      failure.js do
        render status: :unprocessable_entity, nothing: true
      end
    end
  end

  def destroy
    @document = task.documents.find(params[:id])
    @document.mark_as_deleted!

    respond_to do |wants|
      wants.html do
        flash[:notice] = _('Document deleted')
        redirect_to task_path(task)
      end
      wants.js
    end
  end

  def tick_file
    document = Document.find(params[:id])
    if (require_user && document.task.participant?(current_user)) || (require_user && current_user.try(:is_admin?))
      document.toggle! :done
      head :ok
    else
      flash[:error] = _('Only participant can see this page')
      redirect_to task_path(task)
    end
  end

  protected

  def require_owner
    return false unless require_user
    return true if current_user.try(:is_admin?)
    return true unless resource # let it fail
    return true if resource.user_id == current_user.id # owner

    flash[:error] = _('Only the owner can see this page')
    redirect_to task_path(task)
    false
  end

  def require_task_participant_or_editor
    return false unless require_user
    return true if current_user.admin_or_editor?
    return true if task.participant?(current_user) # participant

    flash[:error] = _('Only participant can see this page')
    redirect_to '/'
    false
  end

  def task
    @task ||= association_chain.last
  end
end
