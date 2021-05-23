class AssignmentHistoriesController < InheritedResources::Base
  belongs_to :user
  before_action :require_user
  actions :index

protected
  def collection
    @collection ||= end_of_association_chain.rev_order.with_task.all
  end
end
