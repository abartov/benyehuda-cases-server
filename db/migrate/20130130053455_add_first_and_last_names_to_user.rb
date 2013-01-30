class AddFirstAndLastNamesToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :firstname, :string, :limit => 50
    add_column :users, :lastname, :string, :limit => 40
    print "Populating first/last names based on a simple split...\n"
    User.all.each {|u|
      parts = u.name.split ' '
      u.lastname = parts.pop
      u.firstname = parts.join ' '
      u.save!
    }
    print "Done.\n"
  end

  def self.down
    remove_column :users, :lastname
    remove_column :users, :firstname
  end
end
