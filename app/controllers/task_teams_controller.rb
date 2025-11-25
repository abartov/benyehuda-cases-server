class TaskTeamsController < InheritedResources::Base
  def create
    tt = TaskTeam.where(task_id: task_team_params[:task_id], team_id: task_team_params[:team_id])
    @task_team = if tt.present?
                   tt.first
                 else
                   TaskTeam.create!(task_team_params)
                 end
    @team = @task_team.team
    @task = @task_team.task
    @task_teams = @team.task_teams
    respond_to do |format|
      if params[:add_team_id].present?
        format.json { render json: { task_team_id: @task_team.id, team_id: @team.id, team_name: @team.name } }
      else
        format.js
      end
    end
  end

  def destroy
    tt = TaskTeam.find(params[:id])
    if tt
      @the_id = tt.id
      tt.destroy
    end
    respond_to(&:js)
  end

  private

  def task_team_params
    params.require(:task_team).permit(:task_id, :team_id)
  end
end
