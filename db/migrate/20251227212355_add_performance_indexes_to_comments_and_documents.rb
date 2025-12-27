class AddPerformanceIndexesToCommentsAndDocuments < ActiveRecord::Migration[6.1]
  def change
    # Add composite index on comments(user_id, created_at) for fast lookup of recent comments by user
    add_index :comments, [:user_id, :created_at], name: 'index_comments_on_user_id_and_created_at'

    # Add composite index on documents(user_id, created_at) for fast lookup of recent documents by user
    add_index :documents, [:user_id, :created_at], name: 'index_documents_on_user_id_and_created_at'

    # Add index on users.current_login_at for fast filtering by login time
    add_index :users, :current_login_at, name: 'index_users_on_current_login_at'
  end
end
