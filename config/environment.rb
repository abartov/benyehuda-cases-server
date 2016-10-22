# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
CasesServer::Application.initialize!

# to use ruby debug with Pow do the following:
# echo export RUBY_DEBUG_PORT=20000 >> ./.powenv
#
# to connect:
# rdebug -c -p 20000
if ENV['RUBY_DEBUG_PORT']
  Debugger.start_remote nil, ENV['RUBY_DEBUG_PORT'].to_i
end

#Rails.application.routes.default_url_options[:host] = "52.20.112.68" # EC2 machine
Rails.application.routes.default_url_options[:host] = (GlobalPreference.get(:domain) || "benyehuda.org") rescue "benyehuda.org"
