source 'http://rubygems.org'

gem 'rails', '3.0.20'
gem 'rake', '0.8.7'
gem 'rack', '1.2.6'
gem "builder"
gem "json", '>=1.7.7'
gem "mysql"
gem 'authlogic'
gem 'whenever'
gem 'will_paginate', "2.3.15", :require => 'will_paginate'
gem "tzinfo"
gem 'formtastic'
gem 'sass'
gem 'haml', '3.1.7'
gem 'fast_gettext'
gem 'ruby_parser', :require => false
gem "aasm", '3.0.16'
gem 'mime-types', :require => 'mime/types'
gem "fastercsv"
gem 'airbrake'
gem 'thinking-sphinx', :require => 'thinking_sphinx'
gem 'gravtastic', "2.2.0"
gem 'vlad', '1.4.0', :require => false
gem "RubyInline"
gem "daemons"
gem 'high_voltage', '1.2.1'
gem 'inherited_resources'
gem 'has_scope'
gem 'hoe', '2.8.0'
#gem 'grosser-pomo', :source => "http://gems.github.com/", :version => '>=0.5.1'

gem 'aws-s3', :require => "aws/s3"
gem 'paperclip', '~>2.4.5'  # XXX until we're in the 1.9 land
gem 'cocaine' ,'0.3.2'
#gem 'paperclip', :git => "git://github.com/jeanmartin/paperclip.git", :branch => "master"

gem 'jquery-rails', '>= 1.0.12'

gem 'image_science', :require => false
gem 'rmagick'
gem 'mini_magick'
gem 'nokogiri', '1.5.6' # required by something, and 1.6.0 dropped Ruby 1.8.7 support, so we force it here

gem 'astrails-safe'

# TODO sort this out
gem 'ZenTest', '4.0.0'
gem 'test-unit', '1.2.3'
gem "ruby-debug#{RUBY_VERSION =~ /1.9/ ? '19' : ''}", :require => 'ruby-debug'

group :production do
  gem "passenger", '2.2.11'
end

group :development do
  gem 'rspec-rails'
  gem 'rspec'
  gem 'mocha'
  #gem 'inaction_mailer', :require => 'inaction_mailer/force_load'
  gem 'query_trace', :require => 'query_trace'
  gem 'thin'
end

group :test do
  gem 'rspec-rails'
  gem 'rspec'
  gem 'mocha'
  gem 'factory_girl_rails', '1.4.0'
  #gem 'inaction_mailer', :require => 'inaction_mailer/force_load'
  gem 'query_trace', :require => 'query_trace'
  gem 'rspec2-rails-views-matchers'
end
