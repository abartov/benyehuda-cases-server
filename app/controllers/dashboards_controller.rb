class DashboardsController < InheritedResources::Base
  before_action :require_user
  defaults :resource_class => 'Task', :collection_name => 'tasks', :instance_name => 'task'
  has_scope :order_by, :only => :index, :using => [:includes, :property, :dir]
  has_scope :order_by_state, :only => :index, :using => [:dir]
  actions :index

  def index
    if current_user.admin_or_editor?
      @waiting_volunteers = User.all_volunteers.waiting_for_tasks.all
      @editing_tasks = current_user.editing_tasks.visible_in_my_tasks.order('updated_at desc')
      if params[:sort_by] == 'percent_done'
        @editing_tasks.sort! {|a,b| a.percent_done <=> b.percent_done }
        @editing_tasks.reverse! if params[:dir] == 'DESC'
      end
    end
    super
  end

  protected

  def collection
    @tasks ||= apply_scopes(current_user.assigned_tasks).visible_in_my_tasks.order('updated_at desc').paginate(:page => params[:page], :per_page => params[:per_page])
  end
end
