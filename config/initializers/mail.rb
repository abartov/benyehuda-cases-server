# frozen_string_literal: true

require 'deployment_helpers'

if Rails.env.production? && !DeploymentHelpers.assets_compilation?
  # Settings below assumes we use Gmail's SMTP for sending emails
  # For this you'll need to get Gmail Application Password as described here:
  # https://support.google.com/mail/answer/185833?hl=en
  ActionMailer::Base.smtp_settings = {
    user_name: ENV.fetch('SMTP_USERNAME'),
    password: ENV.fetch('SMTP_PASSWORD'),
    address: ENV.fetch('SMTP_HOST'),
    port: ENV.fetch('SMTP_PORT'),
    domain: ENV.fetch('SMTP_DOMAIN'),
    authentication: 'plain',
    enable_starttls_auto: true
  }
end
