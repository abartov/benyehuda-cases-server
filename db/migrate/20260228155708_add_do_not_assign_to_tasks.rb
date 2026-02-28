class AddDoNotAssignToTasks < ActiveRecord::Migration[6.1]
  def change
    add_column :tasks, :do_not_assign, :boolean, default: false, null: false
  end
end
