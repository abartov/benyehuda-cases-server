# frozen_string_literal: true

require 'site_constants'

Rails.application.routes.default_url_options[:host] = SiteConstants::APP_HOSTNAME
ActionMailer::Base.default_url_options[:host] = SiteConstants::APP_HOSTNAME
