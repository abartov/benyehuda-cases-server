class TeamMembership < ApplicationRecord
  enum team_role: { member: 0, lead: 1, admin: 2 }

  belongs_to :team
  belongs_to :user
end
