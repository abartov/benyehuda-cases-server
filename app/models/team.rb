class Team < ApplicationRecord
  enum status: { active: 0, archived: 1, deprecated: 2 }

  has_and_belongs_to_many :users, join_table: :team_memberships
  has_and_belongs_to_many :tasks, join_table: :task_teams
  has_many :team_memberships, dependent: :destroy
  has_many :task_teams, dependent: :destroy

  def has_member?(user)
    users.include?(user)
  end

  def has_task?(task)
    tasks.include?(task)
  end

  # return users whose role in the team is 'lead'
  def team_leads
    users.joins(:team_memberships).where(team_memberships: {team_role: TeamMembership.team_roles[:lead]})
  end

  def team_lead_memberships
    team_memberships.where(team_role: TeamMembership.team_roles[:lead])
  end

  def team_member_memberships
    team_memberships.where(team_role: TeamMembership.team_roles[:member])
  end

  def user_ids
    users.map(&:id)
  end

  def team_lead_ids
    team_leads.map(&:id)
  end
end
