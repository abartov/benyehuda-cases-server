# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'vlad'
require 'vlad/core'
Vlad.load :scm => :git, :app => nil, :web => nil
require 'vladify/lib/vladify/core'
FastGettext.silence_errors  # XXX

CasesServer::Application.load_tasks
