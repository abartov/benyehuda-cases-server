module ApplicationHelper
  def body_class
    "#{controller.controller_name} #{controller.controller_name}-#{controller.action_name}"
  end

  def hebrew_layout?
    "he" == current_locale
  end

  def current_locale
    'he' # XXX
  end

  def render_tabs
    return unless logged_in?
    buf = "<ul id=\"nav\">"
    TabsHelper::TABS.reverse.each do |tab|
      next if tab[:if] && !current_user.send(tab[:if])

      opts = {}
      opts[:class] = "active" if @current_tab == tab[:name]

      buf += "<li " + (@current_tab == tab[:name] ? 'class="active"' : '') +'>'
      buf += "<a href=\"#{tab[:path]}\"><span>#{I18n.t("tabs.#{tab[:name]}")}</span></a></li>"
    end
    buf += "</ul>"
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
    value ? "&#8730;" : ""
  end
  # replacement for Rails 3.x function
  def link_to_function(name, function, html_options={})
    # return "<a href='javascript:void(0);' onclick='#{function}; return false;'>#{name}</a>"
    content_tag(:a, name, {:href => 'javascript:void(0);', :onclick => "#{function}; return false;"}.merge(html_options))
  end
  def password_edit_title
    if logged_in?
      I18n.t('gettext.change_password')
    elsif @user.active?
      I18n.t('gettext.password_reset')
    else
      I18n.t('gettext.activate_account')
    end
  end

  def password_edit_submit
    if logged_in?
      I18n.t('gettext.change')
    elsif @user.active?
      I18n.t('gettext.reset')
    else
      I18n.t('gettext.activate')
    end
  end
end
