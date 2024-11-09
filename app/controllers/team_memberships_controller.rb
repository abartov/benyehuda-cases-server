class TeamMembershipsController < InheritedResources::Base

  before_action :set_tm, only: %i[show edit update destroy]

  def create
    pp = team_membership_params
    pp[:team_role] = pp[:team_role].to_i
    @team_membership = TeamMembership.create!(pp)
    @team = @team_membership.team
    @team_leads = @team.team_lead_memberships
    @team_members = @team.team_member_memberships
  end

  def update
    @team_membership.update(team_membership_params)
  end

  def destroy
    @the_id = @team_membership.id
    @team_membership.destroy
  end

  private

  def team_membership_params
    params.require(:team_membership).permit(:joined, :left, :team_role, :team_id, :user_id)
  end

  def set_tm
    @team_membership = TeamMembership.find(params[:id])
  end
end
