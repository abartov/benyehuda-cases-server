namespace :gettext do
  task :load_array_find_index do
    require 'array_find_index'
  end

  # GetText's :find task uses Array#find_index which is not available
  # in 1.8.6. preload a backward compat version
  task :find => :load_array_find_index

  desc "sync .po files to db"
  #task :sync => :sync_po_to_db
end

