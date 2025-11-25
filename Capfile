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

# Note: We use custom puma.rake tasks instead of capistrano3-puma
# because the original deployment uses daemon mode with puma-daemon gem

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
