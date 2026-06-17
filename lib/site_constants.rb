# frozen_string_literal: true

require 'deployment_helpers'

def fetch_env_var(name, fallback = '')
  DeploymentHelpers.assets_compilation? ? fallback : ENV.fetch(name)
end

module SiteConstants
  APP_HOSTNAME = fetch_env_var('APP_HOSTNAME', 'tasks.benyehuda.org')

  S3_REGION = fetch_env_var('S3_REGION')
  S3_BUCKET = fetch_env_var('S3_BUCKET')
  AWS_ACCESS_KEY_ID = fetch_env_var('AWS_ACCESS_KEY_ID')
  AWS_SECRET_ACCESS_KEY = fetch_env_var('AWS_SECRET_ACCESS_KEY')
end
