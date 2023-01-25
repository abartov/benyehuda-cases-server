class AddIndexByCreatorIdToTask < ActiveRecord::Migration[6.1]
  def change
    add_index :tasks, :creator_id
  end
end
