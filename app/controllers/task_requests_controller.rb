class TaskRequestsController < ApplicationController
  before_action :require_volunteer

  def create
    current_user.set_task_requested.save!
    respond_to do |format|
      format.html
      format.js
    end
  end
end
