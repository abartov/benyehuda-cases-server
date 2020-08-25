class AddSourceToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :source, :string, limit: 2048
    print "Migrating #{Task.count} tasks' source property to source field..."
    i = 0
    Task.all.each{|t|
      t.source = t.legacy_source
      t.save
      i += 1
      print " #{i}" if i % 100 == 0
    }
    puts "done!"
  end
end
