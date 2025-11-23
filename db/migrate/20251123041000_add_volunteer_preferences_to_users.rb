class AddVolunteerPreferencesToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :volunteer_preferences, :text
  end
end
