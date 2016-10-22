class AddOnBreakToUser < ActiveRecord::Migration
  def change
    add_column :users, :on_break, :boolean
    User.update_all(on_break: false)
  end
end
