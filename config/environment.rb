# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!
Rails.application.routes.default_url_options[:host] = (GlobalPreference.get(:domain) || "benyehuda.org") rescue "benyehuda.org"