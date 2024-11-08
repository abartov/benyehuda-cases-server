class CreateTeamMemberships < ActiveRecord::Migration[6.1]
  def change
    create_table :team_memberships do |t|

      t.bigint "team_id", null: false
      t.index ["team_id"], name: "index_team_memberships_on_team_id"
      #t.references :team, foreign_key: true, type: :bigint
      t.references :user, foreign_key: true, type: :int
      t.datetime :joined
      t.datetime :left
      t.integer :team_role

      t.timestamps
    end
  end
end
