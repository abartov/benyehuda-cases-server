class Admin::TasksController < InheritedResources::Base
  before_filter :require_admin
  actions :index, :new, :create, :edit, :update

  def create
    @task = current_user.created_tasks.create(params[:task])
    create! do |format|
      format.html {redirect_to task_path(@task)}
    end
  end

  def update
    super do |format|
      format.html {redirect_to admin_tasks_path}
    end
  end


protected
  def collection
    @tasks ||= Task.filter(params).paginate(:page => params[:page], :per_page => params[:per_page])
  end
end
