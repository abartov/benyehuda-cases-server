class AddTaskIndexes < ActiveRecord::Migration
  def up
    puts "Adding indexes to Tasks table..."
    add_index(:tasks, :assignee_id)
    add_index(:tasks, :editor_id)
    add_index(:tasks, :state)
    add_index(:tasks, :kind_id)
  end

  def down
  end
end
