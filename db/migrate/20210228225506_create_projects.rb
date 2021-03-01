class CreateProjects < ActiveRecord::Migration
  def change
    create_table(:projects, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci") do |t|
      t.string :name
      t.text :description
      t.integer :status

      t.timestamps null: false
    end
    add_column :tasks, :project_id, :integer

  end
end
