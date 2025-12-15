# Standard Rails I18n configuration
# Migrated from FastGettext::TranslationRepository::Db
AVAILABLE_LOCALES = ['en', 'he', 'ru'].freeze
I18n.available_locales = AVAILABLE_LOCALES
I18n.default_locale = :he
I18n.locale = :he
I18n.enforce_available_locales = false

# Load all locale files from config/locales
I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

WillPaginate::ViewHelpers.pagination_options[:previous_label] = I18n.t('gettext.paginator_previous_page.laquo_previous', default: '&laquo; Previous')
WillPaginate::ViewHelpers.pagination_options[:next_label] = I18n.t('gettext.paginator_previous_page.next_raquo', default: 'Next &raquo;')
