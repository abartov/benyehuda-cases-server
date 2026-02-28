class AddDoNotAssignToTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :do_not_assign, :boolean, default: false, null: false
  end
end
