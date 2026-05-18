require "fast_gettext/translation_repository/db"
FastGettext::TranslationRepository::Db.require_models

FastGettext.add_text_domain 'app', :type => :db, :model => TranslationKey

FastGettext.default_text_domain = 'app'
FastGettext.locale = 'he'
AVAILABLE_LOCALES = FastGettext.available_locales = ['en', 'he', 'ru']
I18n.locale = 'he'
#I18n.locale = :he
I18n.enforce_available_locales = false


begin
  def assets_compilation?
    # Check if we're in assets group (set by rails assets:precompile)
    return true if ENV['RAILS_GROUPS'].to_s.include?('assets')

    # Fallback to checking rake tasks
    if defined?(Rake.application)
      Rake.application.top_level_tasks.any? do |task|
        task.to_s == 'assets:precompile' ||
          task.to_s.start_with?('assets:precompile')
      end
    end
  end

  # The code below requires DB connection, which can be unavailable during assets precompilation
  # so we do it only when it is not an assets compilation rake task
  unless assets_compilation?
    WillPaginate::ViewHelpers.pagination_options[:previous_label] = s_('paginator - previous page|&laquo; Previous')
    WillPaginate::ViewHelpers.pagination_options[:next_label] = s_('paginator - previous page|Next &raquo;')
  end
end
