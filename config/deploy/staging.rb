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
