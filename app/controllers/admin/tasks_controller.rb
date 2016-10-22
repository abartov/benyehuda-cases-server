class Admin::TasksController < InheritedResources::Base
  before_filter :require_admin, :only => [:create, :update, :changes]
  before_filter :require_editor_or_admin, :only => :index
  actions :index, :new, :create, :edit, :update, :destroy, :changes
  has_scope :order_by, :only => :index, :using => [:includes, :property, :dir]
  has_scope :order_by_state, :only => :index, :using => [:dir]
  respond_to :js

  def create
    @task = current_user.created_tasks.build(params[:task])
    resource.admin_state = params[:task][:admin_state] || resource.admin_state
    resource.editor_id = params[:task][:editor_id] || resource.editor_id
    resource.assignee_id = params[:task][:assignee_id] || resource.assignee_id
    create! do |success, failure|
      success.html do
        redirect_to (params[:commit] == _("Save and New")) ? new_admin_task_path : task_path(@task)
      end
    end
  end

  def update
    resource.admin_state = params[:task][:admin_state] || resource.admin_state
    resource.editor_id = params[:task][:editor_id] || resource.editor_id
    resource.assignee_id = params[:task][:assignee_id] || resource.assignee_id
    update! do |success, failure|
      success.html {redirect_to task_path(resource)}
    end
  end

  def index
    if "true" == params[:all]
      # reset
      current_user.search_settings.clear!
    elsif (params.keys & Task::SEARCH_KEYS).blank?
      # load defaults
      params.merge!(current_user.search_settings.retrieve)
    end
    current_user.search_settings.set_from_params!(params)
    default_index_with_search!
  end
  def changes
    @raw_changes = Audit.order('updated_at desc').limit(500).paginate(:page => params[:page], :per_page => 100)
    # group audits by task
    @changes = {}
    @ordered_changes = []
    @raw_changes.each {|c|
      unless @changes.has_key? c.task_id
        @changes[c.task_id] = []
        @ordered_changes << c.task_id
      end
      @changes[c.task_id] << c
    }
  end
  protected
  def collection
    @tasks ||= apply_scopes(Task).filter(params)
  end

  def interpolation_options
    { :task_name => @task.name }
  end
end
