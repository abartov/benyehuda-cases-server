# encoding: utf-8
#
# Seeds for the test environment.
#
# Reference data only. Tests build their own users, tasks and documents through
# the factories in spec/factories; what they cannot invent is the lookup data
# the application assumes is already there, because the code reads it by name or
# by hardcoded id.
#
# Loaded automatically before the suite by spec/rails_helper.rb, and available
# on demand as:
#
#   RAILS_ENV=test bundle exec rake db:seed

load Rails.root.join('db/seeds/reference_data.rb').to_s

puts "test seeds done: #{TaskState.count} task states, #{VolunteerKind.count} volunteer kinds, " \
     "#{Property.count} properties"
