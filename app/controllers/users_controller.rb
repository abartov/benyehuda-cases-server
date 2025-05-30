class UsersController < InheritedResources::Base
  before_action :require_admin, only: %i[index destroy]
  before_action :require_no_user, only: %i[new create]
  before_action :require_owner, only: %i[edit update]
  before_action :require_owner, only: %i[edit update take_break]
  before_action :require_owner_or_public_profile, only: :show
  before_action :set_default_domain, only: :create

  respond_to :html, :js

  actions :create, :update, :index, :destroy, :cancel_task_request

  @@index_name = ENV['is_staging'] == 'true' ? 'staging_user' : 'user'

  def index
    default_index_with_search!
  end

  def new
    @user = User.new
  end

  def take_break
    @user = User.find(params[:id])
    if @user.is_volunteer?
      @user.on_break = true
      flash[:notice] = s_("You're now on break! Request a new task to come out of break.")
      @user.save!
    end
    redirect_to action: :show
  end

  def create
    pps = params.require(:user).permit(:avatar, :name, :email, :password)
    params = user_params
    @user = build_resource
    @user.email = params[:user] && params[:user][:email] || @user.email
    @user.is_admin = true if User.count.zero?
    if @user.save_without_session_maintenance
      @user.deliver_activation_instructions!
      flash[:notice] =
        s_('Your account has been created. Please check your e-mail for your account activation instructions!')
      redirect_to '/'
    else
      render action: :new
    end
  end

  def update
    @user = User.find(params[:id])
    return _remove_avatar if 'true' == params[:remove_avatar]

    uparams = user_params
    # manual update protected attributes
    if current_user.is_admin?
      @user.is_admin = uparams.delete(:is_admin)
      @user.is_volunteer = uparams.delete(:is_volunteer)
      @user.is_editor = uparams.delete(:is_editor)
      @user.email = uparams[:email] || @user.email
    end
    update_resource(resource, uparams)
    render action: :show
  end

  def destroy
    @user = User.find(params[:id])
    if @user.id == current_user.id
      flash[:error] = _('You cannot remove your own account')
      redirect_to users_path
      return
    end
    if 'true' == params[:enable]
      @user.update_attribute(:disabled_at, nil)
      flash[:notice] = _('User enabled')
      redirect_to user_path(@user)
    else
      @user.update_attribute(:disabled_at, Time.zone.now)
      flash[:notice] = _('User disabled')
      redirect_to users_path
    end
  end

  def cancel_task_request
    @user = User.find(params[:id])
    return unless current_user.is_admin? or current_user == @user

    @user.clear_task_requested!
    flash[:notice] = _("Cancelled additional task request for user #{@user.name}")
    redirect_to '/'
  end

  protected

  def public_profile?
    true == params[:public_profile]
  end
  helper_method :public_profile?

  def require_owner_or_public_profile
    return require_owner unless public_profile?

    return false unless require_user
    return true unless resource # let it fail
    # allow colunteers to see public profiles of admins and editors
    return true if current_user.is_volunteer? && resource.admin_or_editor?
    # allow editors and admins to see public profile of volunteers
    return true if resource.is_volunteer? && current_user.admin_or_editor?
    # allow users to see own profiles
    return true if resource.id == current_user.id

    flash[:error] = _('Only registered activists allowed to access this page')
    redirect_to '/'
    false
  end

  def require_owner
    return false unless require_user
    return true unless resource # let it fail
    return true if current_user.try(:is_admin?)
    return true if resource == current_user # owner

    flash[:error] = _('Only the owner can see this page')
    redirect_to '/'
    false
  end

  def collection
    if params[:query].blank?
      @users ||= end_of_association_chain.send('true' == params[:all] ? :by_id : :enabled).active_first.paginate(
        page: params[:page], per_page: params[:per_page]
      )
    else
      q = params[:query].gsub('@', '\\@')
      @users ||= User.send('true' == params[:all] ? :sp_all : :sp_enabled).sp_active_first.search(q, indices: [@@index_name]).paginate(
        page: params[:page], per_page: params[:per_page]
      )
    end
  end

  def resource
    @user ||= params[:id] ? User.find(params[:id]) : current_user
  end

  # this will set global preference :domain to the current domain
  # when we create the first user.
  def set_default_domain
    return unless GlobalPreference.get(:domain).blank?

    GlobalPreference.set!(:domain, request.host_with_port)
  end

  def _remove_avatar
    @user.avatar = nil
    @user.save
    redirect_to user_path(@user)
  end

  def user_params
    params.require('user').permit(:name, :email, :notify_on_comments, :notify_on_status, :zehut, :is_admin, :is_editor,
                                  :is_volunteer, :avatar, user_properties: {}, volunteer_properties: {}, editor_properties: {})
    # params.permit!
  end
end
