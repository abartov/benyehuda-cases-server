# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

# Asaf removed it, because it was easier to work around it by monkey-patching thinking_sphinx on the BY server.  I've reported it here: https://github.com/pat/thinking-sphinx/issues/809
# and submitted a pull request here: https://github.com/pat/thinking-sphinx/pull/1019

# Asaf added this, October 2016
# fugly, but vlad 1.4 is also fugly, injecting methods such as 'options' and 'source' to Kernel or Object, interfering with ThinkingSphinx

#zargs = ARGV.to_s
#vlad_inclusion_keywords = ['vlad','staging','prod']
#vlad_inclusion_keywords.each {|keyword|

#if zargs =~ /#{keyword}/
  require 'vlad'
  require 'vlad/core'
  Vlad.load :scm => :git, :app => nil, :web => nil
  require 'vladify/lib/vladify/core'
#  break
#end
#}
# end fugly bit

#FastGettext.silence_errors  # XXX

CasesServer::Application.load_tasks
