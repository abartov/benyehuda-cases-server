# frozen_string_literal: true

# Production server configuration
set :stage, :production
set :rails_env, :production
set :rack_env, :production

# Server configuration
server 'benyehuda.org', user: 'bybe', roles: %w[app db web]

# Deploy directory
set :deploy_to, '/var/www/tasks.benyehuda.org'

# Application name for whenever crontab
set :whenever_identifier, 'tasks.benyehuda.org'

# Puma configuration for production
set :puma_threads, [1, 5]
set :puma_workers, 3
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log, "#{release_path}/log/puma.error.log"
set :puma_daemonize, true
