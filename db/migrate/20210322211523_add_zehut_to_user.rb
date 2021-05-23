class AddZehutToUser < ActiveRecord::Migration
  def change
    add_column :users, :zehut, :string
  end
end
