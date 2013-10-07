class TasksController < InheritedResources::Base
  before_filter :require_task_participant_or_editor, :only => [:show, :update, :edit]
  before_filter :require_editor_or_admin, :only => [:index, :create]
  actions :index, :show, :update, :create

  EVENTS_WITH_COMMENTS = {"reject" => N_("Task rejected"), "abandon" => N_("Task abandoned"), "finish" => N_("Task completed")}

  # finishing tasks
  def edit
    return unless _allow_event?(resource, :finish, current_user)
    @no_docs_uploaded = resource.documents.uploaded_by(current_user).count.zero?
  end
  def make_comments_editor_only
    @task = Task.find(params[:id])
    @task.comments.each {|c|
      c.editor_eyes_only = true
      c.save!
    }
    redirect_to(@task)
  end

  def create
    @task = Task.find(params[:id])

    return unless _allow_event?(@task, :create_other_task, current_user)

    @chained_task = @task.build_chained_task(params[:task], current_user)
    @comment = @chained_task.comments.first
    if @chained_task.save
      flash[:notice] = _("Task created.")
      render(:update) do |page|
        page.redirect_to task_path(@chained_task)
      end
    else
      render(:update) do |page|
        page[:new_task_container].replaceWith render(:partial => "new_chain_task")
      end
    end
  end

  def index
    #@tasks = Task.unassigned.paginate(:page => params[:page], :per_page => params[:per_page])
    if params[:kind].nil? or params[:kind].blank?
      tasks = Task.unassigned.sort_by {|t| 
        kindname = t.kind.nil? ? '' : t.kind.try(:name) # shouldn't happen -- is only the case in some odd old test items
        kindname + t.updated_at.to_i.to_s # manual sort :( # TODO: figure out how to do this through the assoc
      }
      @tasks = tasks.reverse.paginate(:page => params[:page], :per_page => params[:per_page])
    else
      #params[:state] = :unassigned
      #current_user.search_settings.set_from_params!(params)
      @tasks = Task.unassigned.where(:kind_id => TaskKind.find_by_name(params[:kind]).id).order('updated_at desc').paginate(:page => params[:page], :per_page => params[:per_page])
    end
    
    @assignee = User.find(params[:assignee_id]) if params[:assignee_id]
  end

  def show
    @task = Task.find(params[:id], :include => {:documents => :user})
    @comments = @task.comments.with_user.send(current_user.admin_or_editor? ? :all : :public)
    show!
  end

  def update
    return unless _allow_event?(resource, params[:event], current_user)

    # all security verifications passed in allow_event_for?
    return _event_with_comment(params[:event]) if resource.commentable_event?(params[:event])

    resource.send(params[:event])
    resource.save

    flash[:notice] = _("Task updated")

    redirect_to task_path(resource)
  end

protected
  def require_task_participant_or_editor
    return false unless require_user
    return true if current_user.admin_or_editor?
    return true if resource.participant?(current_user) # participant

    flash[:error] = _("Only participant can see this page")
    redirect_to "/"
    return false
  end

  def _event_with_comment(event)
    unless resource.event_with_comment(event, params[:task])
      render(:update) do |page|
        page["#{event}_task"].html render(:partial => "tasks/#{event}")
      end
      return
    end

    resource.save
    flash[:notice] = s_(resource.class.event_complete_message(event))
    render(:update) do |page|
      page.redirect_to(resource.participant?(current_user) ? task_path(resource) : dashboard_path)
    end    
  end

  def _allow_event?(task, event, user)
    return true if task.allow_event_for?(event, user)

    flash[:error] = _("Sorry, you're not allowed to perfrom this operation")

    respond_to do |wants|
      wants.html {redirect_to task_path(task)}
      wants.js do
        render(:update) do |page|
          page.redirect_to task_path(task)
        end
      end
    end

    false
  end
end
