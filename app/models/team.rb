class Team < ApplicationRecord
  enum status: { active: 0, archived: 1, deprecated: 2 }

  has_and_belongs_to_many :users, join_table: :team_memberships
  has_and_belongs_to_many :tasks, join_table: :task_teams
end
