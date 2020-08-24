class AddFieldsToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :genre, :integer
    add_column :tasks, :independent, :boolean
    add_column :tasks, :include_images, :boolean
  end
end
