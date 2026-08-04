class UsersController < InheritedResources::Base
  before_action :require_admin, :only => [:index, :destroy]
  before_action :require_no_user, :only => [:new, :create]
  before_action :require_owner, :except => [:new, :create, :index]

  def create
    params = user_params
    user = build_resource
    user.is_admin = true if User.count.zero?
    if user.save_without_session_maintenance
      user.deliver_activation_instructions!
      flash[:notice] = "Your account has been created. Please check your e-mail for your account activation instructions!"
      redirect_to login_path
    else
      render :action => :new
    end
  end

  def destroy
    destroy!
    current_user_session.destroy
  end

  protected

  def require_owner
    return false unless require_user
    return true unless resource # let it fail
    return true if current_user.try(:is_admin?)
    return true if resource == current_user # owner

    flash[:error] = "Only the owner can see this page"
    redirect_to "/"
    return false
  end

  def collection
    @users ||= end_of_association_chain.paginate(params[:page]).all
  end

  def resource
    @user ||= params[:id] ? User.find(params[:id]) : current_user
  end

  def build_resource
    raise "Trust is a method from trusted-params plugin which is being discontinued."
    params[:user].try(:trust, :email)
    super
  end

  def user_params
    params.require(:user).permit(:name, :password, :password_confirmation)
  end
end
