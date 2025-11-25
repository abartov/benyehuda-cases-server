class VolunteerRequestsController < InheritedResources::Base
  before_action :require_user
  before_action :require_editor_or_admin, :except => [:create, :new]
  before_action :check_volunteer_request, :only => [:create, :new]
  actions :new, :create, :update, :index, :show

  # new

  def create
    @volunteer_request = current_user.create_volunteer_request(params[:volunteer_request].permit(:preferences , :user_attributes))
    if params[:zehut].present?
      current_user.zehut = params[:zehut]
      current_user.save!
    end
    if @volunteer_request.new_record?
      render :action => "new"
      return
    end

    flash[:notice] = I18n.t('gettext.thank_you_your_request_has_been_posted')
    redirect_to home_path
  end

  # index

  def update
    @volunteer_requests = VolunteerRequest.pending.find(params[:id])
    @volunteer_requests.approve!(current_user)
    # XXX temporarily @volunteer_requests.user.update_attribute(:volunteer_kind_id, params[:volunteer_request][:user_attributes][:volunteer_kind_id])
    flash[:notice] = I18n.t('gettext.volunteer_request_approved')
    redirect_to volunteer_requests_path
  end

protected
  def collection
    @volunteer_requests ||= end_of_association_chain.
      pending.
      by_request_time.
      with_user.
      paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def check_volunteer_request
    return true if current_user.might_become_volunteer?

    flash[:error] = I18n.t('gettext.your_request_has_already_been_posted')
    redirect_to home_path
  end
end
