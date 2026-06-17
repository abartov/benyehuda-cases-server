class DropGlobalPreferences < ActiveRecord::Migration[6.1]
  def change
    drop_table :global_preferences
  end
end
