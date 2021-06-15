class AddIndexByParentId < ActiveRecord::Migration[6.1]
  def change
    add_index :tasks, :parent_id
  end
end
