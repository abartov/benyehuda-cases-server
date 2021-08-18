class CreateAPIUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :api_users do |t|
      t.string :api_key
      t.string :email

      t.timestamps
    end
    add_index :api_users, :api_key, unique: true
    add_index :api_users, :email, unique: true
  end
end
