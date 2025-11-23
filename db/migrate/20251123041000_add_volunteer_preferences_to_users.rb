class AddVolunteerPreferencesToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :volunteer_preferences, :text
    add_column :users, :mobile_phone, :string
    add_column :users, :telephone, :string
    add_column :users, :address, :string
  end
end
