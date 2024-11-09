class AddIndexToAssignmentHistories < ActiveRecord::Migration[6.1]
  def change
    add_index :assignment_histories, :task_id
  end
end
