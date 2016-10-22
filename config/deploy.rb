require "vladify/lib/vladify/delayed_job"
# require "vladify/delayed_job_monit"
# require "vladify/fast_gettext"  # RFCT there's no pomo sync atm
# require "vladify/gettext"
require "vladify/lib/vladify/thinking_sphinx"
# require "vladify/ultrasphinx"
require "vladify/lib/vladify/whenever"
# require "vladify/workling"
require 'vladify/lib/vladify/bundler'


set :repository, "https://github.com/abartov/benyehuda-cases-server.git"

desc "production server"
task :prod do
  set :application, "tasks.benyehuda.org"
#  set :domain, "bybe@52.20.112.68"
  set :domain, "bybe@tasks.benyehuda.org"
end

desc "stage server"
task :staging do
  set :application, "staging.benyehuda.org"
  #set :domain, "bybe@52.20.112.68"
  set :domain, "bybe@tasks.benyehuda.org"
end

# desc "beta server"
# task :beta do
#   set :application, "benyehuda.org"
#   set :domain, "astrails@benyehuda.astrails.com"
# end
# 
# desc "ui server"
# task :ui do
#   set :application, "benyehuda-ui.astrails.com"
#   set :domain, "astrails@benyehuda.astrails.com"
# end
