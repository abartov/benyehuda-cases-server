source 'http://rubygems.org'

gem 'sassc-rails'
gem 'rails', '~>4.2'
gem 'rake'
gem 'rack' # once we upgrade to Rails 5.x, set '>=2.1.4' to avoid vuln
gem "builder"
gem "json"
gem 'rails-i18n'
gem 'activerecord-session_store'
#gem "mysql2", '0.4.9' # Sphinx can't deal with >0.4.9
gem "mysql2", '~> 0.4'
gem 'scrypt', '2.1.1'
#gem 'authlogic', '~>3.7'
gem 'authlogic', '~>4.0'
gem 'whenever'
gem 'will_paginate', :require => 'will_paginate'
gem 'rails_autolink'
gem "tzinfo"
gem 'formtastic'
gem 'haml'
gem 'haml-rails'
# upgrade to Rails 4.x # gem 'fast_gettext'
gem 'gettext_i18n_rails'
gem 'memoist' # replacement for ActionSupport::Memoizable
gem 'protected_attributes' # for Rails 4.x
gem 'activerecord-deprecated_finders' # legacy for Rails 4.x

gem 'ruby_parser', :require => false
gem "aasm", '~>3.4'
gem 'mime-types', :require => 'mime/types'
gem "fastercsv"
gem 'airbrake'
gem 'thinking-sphinx'
gem 'httparty' # for downloading task attachments as one PDF
#gem 'thinking-sphinx', '~>2', :require => 'thinking_sphinx'
gem 'gravtastic', "2.2.0"
gem 'vlad', '1.4.0', :require => false
gem "RubyInline"
gem "daemons"
gem 'high_voltage', '1.2.1'
gem 'inherited_resources'
gem 'has_scope'
gem 'hoe', '2.8.0'

gem 'aws-sdk', '~> 1'
gem 'paperclip', '~>4.0'
gem 'cocaine'

gem 'image_science', :require => false
#gem 'rmagick', '~>2.0' # upgrade safe once we move to Ruby 2.3+
gem 'mini_magick'
gem 'nokogiri'

gem 'astrails-safe'

# TODO sort this out
gem 'ZenTest', '4.0.0'
gem 'test-unit', '1.2.3'

group :test, :development do
  gem 'rspec-rails'
  gem 'rspec'
  gem 'mocha'
  #gem 'inaction_mailer', :require => 'inaction_mailer/force_load'
  gem 'query_trace', :require => 'query_trace'
  gem 'thin'
end

group :test do
  gem 'factory_girl_rails', '1.4.0'
  #gem 'inaction_mailer', :require => 'inaction_mailer/force_load'
  gem 'rspec2-rails-views-matchers'
end

gem 'byebug'
