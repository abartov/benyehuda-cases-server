require "fast_gettext/translation_repository/db"
FastGettext::TranslationRepository::Db.require_models

FastGettext.add_text_domain 'app', :type => :db, :model => TranslationKey

FastGettext.default_text_domain = 'app'
FastGettext.locale = 'he'
AVAILABLE_LOCALES = FastGettext.available_locales = ['en', 'he', 'ru']
I18n.locale = 'he'
#I18n.locale = :he
I18n.enforce_available_locales = false

WillPaginate::ViewHelpers.pagination_options[:previous_label] = s_('paginator - previous page|&laquo; Previous')
WillPaginate::ViewHelpers.pagination_options[:next_label] = s_('paginator - previous page|Next &raquo;')
