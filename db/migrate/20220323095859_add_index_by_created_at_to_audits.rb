class AddIndexByCreatedAtToAudits < ActiveRecord::Migration[6.1]
  def change
    add_index :audits, [:user_id, :created_at]
  end
end
