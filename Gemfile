source 'http://rubygems.org'

gem 'rails', '~>3.2'
gem 'rake'
gem 'rack'
gem "builder"
gem "json", '>=1.7.7'
gem "mysql2", '~> 0.3.10' # Rails 3.x can't deal with 0.4.x
gem 'authlogic'
gem 'whenever'
gem 'will_paginate', :require => 'will_paginate'
gem 'rails_autolink'
gem "tzinfo"
gem 'formtastic'
gem 'sass'
gem 'haml'
gem 'fast_gettext'
gem 'rails_legacy_mapper' # for backward compatibility with 3.0.x routing
#gem 'protected_attributes' # for Rails 4.x
gem 'ruby_parser', :require => false
gem "aasm", '3.0.16'
gem 'mime-types', :require => 'mime/types'
gem "fastercsv"
gem 'airbrake'
gem 'thinking-sphinx', '~> 3.2.0'

#gem 'thinking-sphinx', '~>2', :require => 'thinking_sphinx'
gem 'gravtastic', "2.2.0"
#gem 'vlad', :require => false
gem 'vlad', '1.4.0', :require => false
gem "RubyInline"
gem "daemons"
gem 'high_voltage', '1.2.1'
gem 'inherited_resources'
gem 'has_scope'
gem 'hoe', '2.8.0'
#gem 'activerecord-session_store' # for Rails 4.x
#gem 'grosser-pomo', :source => "http://gems.github.com/", :version => '>=0.5.1'

gem 'aws-sdk', '~> 1'
#gem 'aws-s3', :require => "aws/s3"
#gem 'paperclip'
gem 'paperclip', '~>2.8'  # upgrading to 3.x would take some changes, around the removed to_file method
#gem 'paperclip', '~>2.4.5'  # XXX until we're in the 1.9 land
gem 'cocaine' ,'0.4.0' # paperclip 2.8 works with this version; Paperclip 3.x works with latest
#gem 'paperclip', :git => "git://github.com/jeanmartin/paperclip.git", :branch => "master"

#gem 'jquery-rails', '>= 1.0.12'

gem 'image_science', :require => false
gem 'rmagick'
gem 'mini_magick'
gem 'nokogiri'

gem 'astrails-safe'

# TODO sort this out
gem 'ZenTest', '4.0.0'
gem 'test-unit', '1.2.3'

#group :production do
#  gem "passenger"
#end

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
