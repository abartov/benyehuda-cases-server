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
      buf += "<a href=\"#{tab[:path]}\"><span>#{s_(tab[:title])}</span></a></li>"
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
      _("Change Password")
    elsif @user.active?
      _("Password Reset")
    else
      _("Activate Account")
    end
  end

  def password_edit_submit
    if logged_in?
      _("Change")
    elsif @user.active?
      _("Reset")
    else
      _("Activate")
    end
  end
end
