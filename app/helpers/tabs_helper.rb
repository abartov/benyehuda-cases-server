module TabsHelper
  I18n.locale = 'he'

  TABS = [
    {:name => :translations, :title => 'tabs.translations', :path => "/translation_keys", :if => :is_admin?},
    {:name => :global_prefs, :title => 'tabs.global_prefs', :path => "/global_preferences", :if => :is_admin?},
    {:name => :site_notices, :title => 'tabs.site_notices', :path => "/site_notices", :if => :is_admin?},
    {:name => :object_prefs, :title => 'tabs.object_prefs', :path => "/properties", :if => :is_admin?},
    {:name => :reports, :title => 'tabs.reports', :path => "/report", :if => :is_admin?},
    {:name => :profile, :title => 'tabs.profile', :path => "/profile"},
    {:name => :volunteer_requests, :title => 'tabs.volunteer_requests', :path => "/volunteer_requests", :if => :admin_or_editor?},
    {name: :teams, title: 'tabs.teams', path: "/teams", if: :is_admin?},
    {:name => :users, :title => 'tabs.users', :path => "/users", :if => :is_admin?}, 
    {:name => :tasks_admin, :title => 'tabs.tasks_admin', :path => "/admin/tasks", :if => :admin_or_editor?},
    {:name => :dashboard, :title => 'tabs.dashboard', :path => "/dashboard"},
  ].freeze

  def tabs_by_name
    @tabs_by_name ||= TABS.inject({}) do |res, tab|
      res[tab[:name]] = tab
      res
    end
  end

  def set_tab(name, page_title = nil)
    name = name.to_sym
    @current_tab = name
    case page_title
    when String
      @page_title = page_title
      render_page_title
    when NilClass
      @page_title ||= I18n.t(tabs_by_name[name][:title])
      render_page_title
    end
  end

  def render_page_title
    content_tag(:h1, @page_title.html_safe)
  end
end
