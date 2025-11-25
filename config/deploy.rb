# frozen_string_literal: true

# config valid for current version and target gem releases
lock '~> 3.19'

set :application, 'benyehuda-cases-server'
set :repo_url, 'https://github.com/abartov/benyehuda-cases-server.git'

# Default branch is :master
# Ask which branch to deploy (or use main/master by default)
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
append :linked_files, 'config/database.yml', 'config/credentials.yml.enc', 'config/master.key'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system', 'public/attachments', 'vendor/bundle', 'db/sphinx'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# RVM configuration
set :rvm_type, :user
set :rvm_ruby_version, '3.2.1'

# Bundler configuration
set :bundle_flags, '--deployment --quiet'
set :bundle_without, %w[test development].join(' ')

namespace :deploy do
  after :finishing, 'deploy:cleanup'
  after :publishing, 'sphinx:rebuild'
  after :publishing, 'whenever:update'
  after :publishing, 'delayed_job:restart'
end
