class AddDoneToDocument < ActiveRecord::Migration
  def self.up
    add_column :documents, :done, :boolean
  end

  def self.down
    remove_column :documents, :done
  end
end
