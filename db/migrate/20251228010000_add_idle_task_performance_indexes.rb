class AddIdleTaskPerformanceIndexes < ActiveRecord::Migration[6.1]
  def change
    # Index on tasks.updated_at for finding idle tasks
    # Used in: Task.where('tasks.updated_at < ?', idle_since)
    add_index :tasks, :updated_at, name: 'index_tasks_on_updated_at'

    # Composite index on documents(task_id, created_at) for checking recent document uploads
    # Used in: task.documents.where('created_at >= ?', idle_since)
    add_index :documents, [:task_id, :created_at], name: 'index_documents_on_task_id_and_created_at'

    # Composite index on audits for finding document done changes
    # Used in: Audit.where(auditable_type: 'Document').where(auditable_id: ...).where('created_at >= ?', idle_since)
    add_index :audits, [:auditable_type, :auditable_id, :created_at],
              name: 'index_audits_on_type_id_and_created_at'
  end
end
