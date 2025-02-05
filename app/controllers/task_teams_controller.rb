class TaskTeamsController < InheritedResources::Base
  def create
    tt = TaskTeam.where(task_id: task_team_params[:task_id], team_id: task_team_params[:team_id])
    tt = if tt.present?
           tt.first
         else
           TaskTeam.create!(task_team_params)
         end
    @team = tt.team
    @task_teams = @team.task_teams
    respond_to(&:js)
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
