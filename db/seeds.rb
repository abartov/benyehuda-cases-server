# encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Reference data (task states, volunteer kinds, properties) lives in
# db/seeds/reference_data.rb, shared by every environment and safe to re-run.
# Anything below that line is throwaway sample content for a fresh development
# database.

env_seeds = Rails.root.join("db/seeds/#{Rails.env}.rb")
if env_seeds.exist?
  load env_seeds.to_s
  return
end

load Rails.root.join('db/seeds/reference_data.rb').to_s

# --- Sample content ----------------------------------------------------------
#
# Destructive, and guarded accordingly: this wipes users and tasks, which is
# ruinous against anything but an empty development database.
unless Rails.env.development?
  puts "reference data seeded; skipping destructive sample content in #{Rails.env}"
  return
end

User.delete_all
User.create([{name: 'testuser 1', email: 'testuser1@mailinator.com', is_volunteer: true}, {name: 'testuser 2', email: 'testuser2@mailinator.com', is_volunteer: true}, {name: 'testuser editor', email:'testeditor@mailinator.com', is_editor: true, is_volunteer: true}])
Task.delete_all
Task.create([{name: 'משימת בדיקה / חיים נחמן ביאליק', kind_id: :הקלדה, creator: User.find_by_name('testuser editor')}])
puts "seeds done"
