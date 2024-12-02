class TeamMembershipsController < InheritedResources::Base
  before_action :set_tm, only: %i[show edit update destroy]

  def create
    pp = team_membership_params
    pp[:team_role] = pp[:team_role].to_i
    if allowed?
      @team_membership = TeamMembership.create!(pp)
      @team = @team_membership.team
      @team_leads = @team.team_lead_memberships
      @team_members = @team.team_member_memberships
    else
      head :forbidden
    end
  end

  def update
    if allowed?
      @team_membership.update(team_membership_params)
    else
      head :forbidden
    end
  end

  def destroy
    if allowed?
      @the_id = @team_membership.id
      @team_membership.destroy
    else
      head :forbidden
    end
  end

  def leave
    @team_membership = TeamMembership.find(params[:id])
    if current_user.id == @team_membership.user_id || current_user.admin_or_editor?
      @the_id = @team_membership.id
      @team_membership.destroy
    else
      head :forbidden
    end
  end

  private

  def team_membership_params
    params.require(:team_membership).permit(:joined, :left, :team_role, :team_id, :user_id)
  end

  def set_tm
    @team_membership = TeamMembership.find(params[:id])
  end

  def allowed?
    relevant_user_id = params[:team_membership].present? ? team_membership_params[:user_id].to_i : @team_membership.user_id
    current_user.admin_or_editor? || current_user.id == relevant_user_id
  end
end
