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
    haml_tag(:ul, :id => "nav") do #  :class => "tabs") do
      TabsHelper::TABS.reverse.each do |tab|
        next if tab[:if] && !current_user.send(tab[:if])

        opts = {}
        opts[:class] = "active" if @current_tab == tab[:name]

        haml_tag(:li, opts) do
          haml_tag(:a, :href => tab[:path]) do
            haml_tag :span, s_(tab[:title])
          end
        end
      end
    end
  end

  def site_notices
    SiteNotice.active.each do |sn|
      haml_tag(:div, sn.html.html_safe, :class => "site-notice")
    end
  end

  def boolean_property(value)
    value ? "&#8730;" : ""
  end
  # replacement for Rails 3.x function
  def link_to_function(name, function, html_options={})
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
