class UserSessionController < InheritedResources::Base
  unloadable
  actions :new, :create, :destroy
  before_filter :require_user, :only => :destroy
  defaults :singleton => true

  def create
    sess = UserSession.create(email: params[:user_session][:email], password: params[:user_session][:password], remember_me: params[:user_session][:remember_me])
    if sess.valid?
      sess.save
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

  def destroy
    destroy! do |wants|
      wants.html {redirect_to login_path}
    end
  end

  private
  def resource
    @object ||= current_user_session
  end

end
