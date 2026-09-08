class AddEmailFrequencyToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :email_frequency, :string, limit: 16, null: false, default: 'unlimited'
  end
end
