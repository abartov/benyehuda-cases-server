module ApplicationHelper
  def body_class
    "#{controller.controller_name} #{controller.controller_name}-#{controller.action_name}"
  end

  def hebrew_layout?
    'he' == current_locale
  end

  def current_locale
    'he' # XXX
  end

  def restrict_access_to_developers
    if params[:api_key].blank?
      error_code = ErrorCodes::DEVELOPER_KEY_MISSING
      error_msg = 'please acquire a developer key'
      error!({ error_msg: error_msg, error_code: error_code }, 401)
    else
      user = APIUser.where(api_key: params[:api_key])
      Rails.logger.info "API call: #{headers}\tWith params: #{params.inspect}" if ENV['DEBUG']
      if user.blank?
        begin
          raise
        rescue StandardError => e
          AuditLog.create data: "unauthenticated user access from #{request.ip}",
                          backtrace: e.backtrace.to_s.truncate(250)
        end
        error_code = ErrorCodes::BAD_AUTHENTICATION_PARAMS
        error_msg = 'invalid developer key'
        error!({ error_msg: error_msg, error_code: error_code }, 401)
        # LogAudit.new({env:env}).execute
      end
    end
  end

  def render_tabs
    return unless logged_in?

    buf = '<ul id="nav">'
    TabsHelper::TABS.reverse.each do |tab|
      next if tab[:if] && !current_user.send(tab[:if])

      opts = {}
      opts[:class] = 'active' if @current_tab == tab[:name]

      buf += '<li ' + (@current_tab == tab[:name] ? 'class="active"' : '') + '>'
      buf += "<a href=\"#{tab[:path]}\"><span>#{I18n.t("tabs.#{tab[:name]}")}</span></a></li>"
    end
    buf += '</ul>'
    buf
  end

  def site_notices
    buf = ''
    SiteNotice.active.each do |sn|
      buf += "<div class='site-notice'>#{sn.html.html_safe}</div>"
    end
    buf
  end

  def boolean_property(value)
    value ? '&#8730;' : ''
  end

  # replacement for Rails 3.x function
  def link_to_function(name, function, html_options = {})
    # return "<a href='javascript:void(0);' onclick='#{function}; return false;'>#{name}</a>"
    content_tag(:a, name,
                { href: 'javascript:void(0);', onclick: "#{function}; return false;" }.merge(html_options))
  end

  def password_edit_title
    if logged_in?
      _('Change Password')
    elsif @user.active?
      _('Password Reset')
    else
      _('Activate Account')
    end
  end

  def password_edit_submit
    if logged_in?
      _('Change')
    elsif @user.active?
      _('Reset')
    else
      _('Activate')
    end
  end
end
