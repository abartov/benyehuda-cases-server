# frozen_string_literal: true

# Staging server configuration
set :stage, :staging
set :rails_env, :production  # Staging uses production Rails environment
set :rack_env, :production

# Server configuration
server 'benyehuda.org', user: 'bybe', roles: %w[app db web]

# Deploy directory
set :deploy_to, '/var/www/staging.tasks.benyehuda.org'

# Application name for whenever crontab
set :whenever_identifier, 'staging.tasks.benyehuda.org'

# Set staging environment variable
set :default_env, { is_staging: 'true' }

# Puma configuration for staging
set :puma_threads, [1, 1]
set :puma_workers, 0
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log, "#{release_path}/log/puma.error.log"
set :puma_daemonize, true
