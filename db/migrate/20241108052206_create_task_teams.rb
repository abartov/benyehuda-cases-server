class CreateTaskTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :task_teams do |t|
      t.bigint "team_id", null: false
      t.index ["team_id"], name: "index_team_memberships_on_team_id"
      t.references :task, foreign_key: true, type: :int

      t.timestamps
    end
  end
end
