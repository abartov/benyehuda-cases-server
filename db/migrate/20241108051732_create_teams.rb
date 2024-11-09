class CreateTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :teams do |t|
      t.string :name
      t.boolean :open
      t.mediumtext :description
      t.integer :status
      t.date :targetdate

      t.timestamps
    end
  end
end
