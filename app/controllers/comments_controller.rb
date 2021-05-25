class CommentsController < InheritedResources::Base
  belongs_to :task
  before_action :require_task_participant, :only => :create
  before_action :require_admin, :only => :destroy

  actions :create, :destroy
  respond_to :js

  # destroy

  def create
    @comment = task.comments.build(comment_params[:comment])
    @comment.user = current_user
    remove_extra_params
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
    remove_extra_params
    destroy!
    flash[:notice] = nil
  end

protected
  def task
    @task ||= association_chain.last
  end
  def comment_params
    params.require(:comment).permit(:message, :editor_eyes_only)
  end
  def remove_extra_params
    params[:comment].each{|k, v| params[k] = v} if params[:comment].present?
    ['controller','action','comment','utf8','_method','authenticity_token','commit'].each{|key| params.delete(key)}
  end
end
