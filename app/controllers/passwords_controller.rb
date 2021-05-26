class PasswordsController < InheritedResources::Base
  unloadable
  defaults :resource_class => User, :instance_name => :user

  actions :new, :update, :edit

  before_action :require_no_user, :except => [:edit, :update, :reset_password_by_editor]
  before_action :require_editor, :only => [:reset_password_by_editor]

  # new! + new.html.haml

  def create
    @user = User.find_by_email(params[:user][:email])
    do_create(false)
  end

  def reset_password_by_editor
    @user = User.find(params[:id])
    # @user already populated by users#reset_password
    do_create(true)
  end
  def edit
    return unless load_user_using_perishable_token(true)
    edit!
  end

  def update
    return unless load_user_using_perishable_token

    unless resource.activated_at
      resource.activated_at = Time.now
      @activated = true
    end
    remove_extra_params
    update! do |success, failure|
      if resource.errors.empty?
        @user.send(@activated ? :deliver_activation_confirmation! : :deliver_password_reset_confirmation!)
      else
        resource.activated_at = nil if @activated # need to revert so that the password_edit_title will set right title
      end

      success.html {redirect_to profile_path}
      failure.html {render :action => "edit"}
    end

  end

  private
  def remove_extra_params
    params[:user].each{|k, v| params[k] = v} if params[:user].present?
    ['controller','action','user','utf8','_method','authenticity_token','commit'].each{|key| params.delete(key)}
  end

  def do_create(by_editor)
    if @user
      @user.deliver_password_reset_instructions!
      if @user.activated_at
        # user is already active
        if by_editor
          flash[:notice] = _("Instructions to reset their password have been e-mailed to the user.")
        else
          flash[:notice] = _("Instructions to reset your password have been emailed to you. Please check your email.")
        end
      else
        flash[:notice] = _("Instructions to activate your account have been emailed to you. Please check your email.")
      end
      if logged_in?
        redirect_to dashboard_path
      else
        redirect_to '/'
      end 
    else
      flash[:error] = _("No user was found with that email address")
      render :action => :new
    end
  end

  def build_resource
    @user ||= User.new
  end

  def resource
    @user ||= params[:id] ? User.find_using_perishable_token(params[:id]) : current_user
  end

  def load_user_using_perishable_token(with_activation_check = false)
    resource

    if with_activation_check
      if current_user && @user && !@user.activated_at
        flash[:error] = _("Please log out to activate new account")
        redirect_to profile_path
        return false
      end
    end
    unless resource
      flash[:error] = _(<<-END
        We're sorry, but we could not locate your account.
        If you are having issues try copying and pasting the URL
        from your email into your browser or restarting the
        reset password process.
      END
      )
      redirect_to new_password_path
      return false
    end
    true
  end

end
