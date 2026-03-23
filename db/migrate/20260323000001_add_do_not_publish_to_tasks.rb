class AddDoNotPublishToTasks < ActiveRecord::Migration[6.1]
  def change
    add_column :tasks, :do_not_publish, :boolean, default: false, null: false
    add_index :tasks, :do_not_publish
  end
end
