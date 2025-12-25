class AddCongratulatedAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :congratulated_at, :datetime
  end
end
