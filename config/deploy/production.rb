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
