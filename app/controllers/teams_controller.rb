class TeamsController < ApplicationController
  before_action :set_team, only: %i[show edit update destroy mass_message]
  before_action :require_admin, only: %i[create edit update destroy mass_message]

  # GET /teams
  def index
    @teams = Team.all
  end

  # GET /teams/new
  def new
    @team = Team.new
    @team_leads = []
    @team_members = []
    @task_teams = []
  end

  # POST /teams
  def create
    @team = Team.new(team_params)
    if @team.save
      redirect_to edit_team_path(@team), notice: 'Team was successfully created.'
    else
      render :new
    end
  end

  # GET /teams/1
  def show
    @team_leads = @team.team_lead_memberships
    @team_members = @team.team_member_memberships
    @task_teams = @team.task_teams
  end

  # GET /teams/1/edit
  def edit
    @team_leads = @team.team_lead_memberships
    @team_members = @team.team_member_memberships
    @task_teams = @team.task_teams
  end

  # PATCH/PUT /teams/1
  def update
    if @team.update(team_params)
      redirect_to edit_team_path(@team), notice: 'Team was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /teams/1
  def destroy
    @team.destroy
    redirect_to teams_url, notice: 'Team was successfully destroyed.'
  end

  # POST /teams/1/mass_message
  def mass_message
    @team.users.each do |user|
      Notification.team_mass_message(user, @team, params[:message].html_safe).deliver
    end
    redirect_to team_path(@team), notice: I18n.t('teams.mass_message_sent')
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_team
      @team = Team.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def team_params
      params.require(:team).permit(:name, :description, :status, :targetdate, :open)
    end
end