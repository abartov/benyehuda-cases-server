# frozen_string_literal: true

# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# Load SCM plugin (Git)
require 'capistrano/scm/git'
install_plugin Capistrano::SCM::Git

# Load RVM support
require 'capistrano/rvm'

# Load bundler support
require 'capistrano/bundler'

# Load Rails support (includes migrations and assets)
require 'capistrano/rails'

# Load Puma support with systemd (must be after rvm)
require 'capistrano/puma'
install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd

# Load thinking-sphinx support
require 'thinking_sphinx/capistrano'
# require 'capistrano/thinking_sphinx'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
