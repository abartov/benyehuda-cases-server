class CreatePendingNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :pending_notifications do |t|
      t.string :recipient_email, limit: 100, null: false
      t.string :notification_type, limit: 128, null: false
      t.text :notification_data, null: false
      # No updated_at: rows are written once and deleted, never updated.
      t.datetime :created_at, null: false
    end

    # Deliberately no foreign key to users: the buffer is keyed on an address
    # so that recipients without an account work too. PendingNotification#resolvable?
    # and PurgeStaleBufferedNotifications exist to cope with that.
    add_index :pending_notifications, %i[recipient_email created_at]
    add_index :pending_notifications, :created_at
  end
end
