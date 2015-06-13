class CommentsController < InheritedResources::Base
  belongs_to :task
  before_filter :require_task_participant, :only => :create
  before_filter :require_admin, :only => :destroy

  actions :create, :destroy
  respond_to :js

  # destroy

  def create
    @comment = task.comments.build(params[:comment])
    @comment.user = current_user
    create! do |success, failure|
      success.js { 
        respond_to do |format|
          format.html
          format.js
        end
      }
      failure.js {
        render :partial => 'failure'
      }
    end
    flash[:notice] = nil
  end

  def destroy
    destroy!
    flash[:notice] = nil
  end

protected
  def task
    @task ||= association_chain.last
  end
end
