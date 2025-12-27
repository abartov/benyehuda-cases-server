class CreateTaskIdleReminders < ActiveRecord::Migration[6.1]
  def change
    create_table :task_idle_reminders do |t|
      t.integer :task_id, null: false
      t.integer :user_id, null: false
      t.datetime :sent_at, null: false

      t.timestamps
    end

    add_index :task_idle_reminders, :task_id
    add_index :task_idle_reminders, :user_id
    add_index :task_idle_reminders, [:task_id, :user_id]
    add_index :task_idle_reminders, :sent_at
  end
end
