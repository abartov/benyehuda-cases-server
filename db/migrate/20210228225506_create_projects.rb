class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.integer :status

      t.timestamps null: false
    end
    add_column :tasks, :project_id, :integer

  end
end
