class TeamsController < ApplicationController
  before_action :set_team, only: [:edit, :update, :destroy]

  # GET /teams
  def index
    @teams = Team.all
  end

  # GET /teams/new
  def new
    @team = Team.new
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