source 'https://rubygems.org'

gem 'activerecord-session_store'
gem 'builder'
gem 'json', '~>2'
gem 'marcel', '~>1'
gem 'rack', '>=2.1.4'
gem 'rails', '~> 7.0'
gem 'rails-i18n', '~> 7.0'
gem 'rake'
gem 'rexml' # required by xml-simple but not yet listed as a dependency in 1.18
gem 'sassc-rails'
# gem "mysql2", '0.4.9' # Sphinx can't deal with >0.4.9
gem 'aasm', '~> 4' # , '~>3.4'
gem 'airbrake'
gem 'authlogic' # , '~>4.0'
gem 'bootsnap'
gem 'daemons'
gem 'fastercsv'
gem 'formtastic'
gem 'gettext'
gem 'gettext_i18n_rails'
gem 'gravtastic', '2.2.0'
gem 'haml'
gem 'haml-rails'
gem 'has_scope'
gem 'high_voltage', '1.2.1'
gem 'hoe', '2.8.0'
gem 'httparty' # for downloading task attachments as one PDF
gem 'inherited_resources'
gem 'memoist' # replacement for ActionSupport::Memoizable
gem 'mime-types', require: 'mime/types'
gem 'mysql2', '~> 0.4'
gem 'rails_autolink'
gem 'RubyInline'
gem 'ruby_parser', require: false
gem 'scrypt', '2.1.1'
gem 'thinking-sphinx'
gem 'tzinfo'
gem 'uglifier'
gem 'vlad', '1.4.0', require: false
gem 'whenever', require: false
gem 'will_paginate', require: 'will_paginate'

gem 'aws-sdk-s3', '~> 1'
gem 'kt-paperclip' # the maintained version of paperclip
# gem 'ruby-vips' # for concatenating JPEGs and PDFs with less memory

gem 'image_science', require: false
gem 'mini_magick'
gem 'nokogiri'
gem 'rails-jquery-autocomplete', '>= 1.0.5' # for auto-completion

gem 'grape' # for API
gem 'grape-entity' # for Grape entities exposure
gem 'puma'
gem 'scanf' # no longer stdlib in Ruby 2.7+

group :test, :development do
  gem 'factory_bot_rails'
  # gem 'ZenTest', '4.0.0'
  gem 'grape-entity-matchers'
  gem 'mocha'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'test-unit'
  # gem 'inaction_mailer', :require => 'inaction_mailer/force_load'
  #  gem 'query_trace', :require => 'query_trace'
  gem 'debug'
  gem 'listen'
  gem 'rubocop', require: false
end

group :test do
  # gem 'factory_girl_rails', '~> 4.5'
  # gem 'factory_girl_rails', '1.4.0'
  # gem 'inaction_mailer', :require => 'inaction_mailer/force_load'
  gem 'database_cleaner-active_record'
  gem 'rspec2-rails-views-matchers'
end

group :development do
  gem 'web-console'
end

group :production do
  gem 'lograge'
  gem 'puma-daemon'
end
