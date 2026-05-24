class AddSuppressAnniversaryGreetingToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :suppress_anniversary_greeting, :boolean, default: false, null: false
  end
end
