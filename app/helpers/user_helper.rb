module UserHelper

  ROLES = {
    "editor" => 'user_role.editor',
    "volunteer" => 'user_role.volunteer',
    "admin" => 'user_role.admin'
  }

  def when_volunteer
    yield if current_user.is_volunteer?
  end

  def when_editor
    yield if current_user.is_editor?
  end

  def when_user_volunteer
    yield if @user.is_volunteer?
  end

  def when_user_editor
    yield if @user.is_editor?
  end

  def user_roles(roles)
    return "No roles defined" if roles.blank?
    roles.map{ |r| I18n.t(ROLES[r])}.join(", ")
  end

  def when_editor_or_admin
    yield if current_user.admin_or_editor?
  end

  def person_link(user)
    return "" unless user
    return I18n.t('gettext.me') if user.id == current_user.id
    link_to(h(user.name), profiles_path(user))
  end

  def activation_email_links(user)
    link_opts = 
    "".tap do |res|
      if user.activation_email_sent_at
        res << user.activation_email_sent_at.to_s
        res << " " << send_activation_link(user, I18n.t('activation_email.resend')) unless user.activated_at
      else
        res << send_activation_link(user, I18n.t('activation_email.send_activation_email'))
      end
    end
  end

  def email_notifications(user)
    [].tap do |res|
      res << I18n.t('gettext.when_a_comment_added_to_my_task') if user.notify_on_comments?
      res << I18n.t('gettext.when_my_task_status_changed') if user.notify_on_status?
      res << I18n.t('notifications.none') if res.blank?
    end.join(", ")
  end

  def avatar_for(user, style = :thumb)
    user.avatar? ? user.avatar.url(style) : user.gravatar_url(:size => User.style_to_size(style), :secure => true)
  end

  def user_css_class(user)
    if user.disabled_at
      "disabled-user"
    else
      ""
    end
  end

protected
  def send_activation_link(user, text)
    link_to text, user_activation_instructions_path(
      user,
      :page => params[:page],
      :query => params[:query],
      :all => params[:all]
    ), :method => :post, :confirm => (I18n.t('gettext.send_activation_email_to_user_are_you_sure', user: "#{h(user.name)} <#{user.email}>"))
  end
end
