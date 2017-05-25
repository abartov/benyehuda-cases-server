class AddIndexesToDocuments < ActiveRecord::Migration
  def change
    add_index :documents, :task_id
  end
end
