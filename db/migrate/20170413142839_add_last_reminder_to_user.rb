class AddLastReminderToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_reminder, :date
  end
end
