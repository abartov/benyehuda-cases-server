class DocumentsController < InheritedResources::Base
  belongs_to :task
  before_filter :require_task_participant, :only => [:new, :create, :show, :tick_file]
  before_filter :require_owner, :only => :destroy
  actions :new, :create, :destroy, :show
  layout nil

  # new - shouldn't be used

  # show

  # create
  def create
    @document = task.prepare_document(current_user, params[:document])

    create! do |success, failure|
      success.js do
        respond_to do |format|
          format.html 
          format.js 
        end
      end
      success.html {redirect_to task_path(task); flash[:notice] = nil}
      failure.js do
        render :status => :unprocessable_entity, :nothing => true
      end
    end
  end

  def destroy
    document = task.documents.find(params[:id])
    document.mark_as_deleted!

    respond_to do |wants|
      wants.html do
        flash[:notice] = _("Document deleted")
        redirect_to task_path(task)
      end
      wants.js do
        render(:update) do |page|
          page[dom_id(document)].remove
        end
      end
    end
  end
  def tick_file
    document = Document.find(params[:id])
    document.toggle! :done
    render :nothing => true
  end

  protected

  def require_owner
    return false unless require_user
    return true if current_user.try(:is_admin?)
    return true unless resource # let it fail
    return true if resource.user_id == current_user.id # owner

    flash[:error] = _("Only the owner can see this page")
    redirect_to task_path(task)
    return false
  end

  def task
    @task ||= association_chain.last
  end
end
