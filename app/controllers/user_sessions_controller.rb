class UserSessionsController < InheritedResources::Base
  unloadable
  actions :new, :create, :destroy
  before_filter :require_user, :only => :destroy
  defaults :singleton => true

  def do_create(object, &block)
    respond_with_dual_blocks(object, {}, &block)
  end

  def create
    byebug
    @user_session = UserSession.create(email: params[:user_session][:email], password: params[:user_session][:password], remember_me: params[:user_session][:remember_me])
    do_create(@user_session) do |success, failure|
      success.html do
        unless current_user.nil?
          if current_user.disabled?
            flash[:error] = _("Your account has been disabled, please contact support.")
            flash.delete(:notice)
            current_user_session.destroy
            redirect_to login_path
          else
            redirect_to home_path
          end
        else
          current_user_session.destroy unless current_user_session.nil?
          redirect_to home_path
        end
      end
    end
  end

  def destroy
    current_user_session.destroy unless current_user_session.nil?
    redirect_to login_path
  end

  private
  def resource
    @object ||= current_user_session
  end

end
