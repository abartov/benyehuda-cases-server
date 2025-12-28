module TeamsHelper
  def prep_for_edit
    @team_leads = @team.team_lead_memberships
    @team_members = @team.team_member_memberships
    @tasks_by_state = TaskState.pluck(:name).map { |s| [s, []] }.to_h
    @task_teams = @team.task_teams.includes(:task).order('tasks.state')
    @task_teams.each do |tt|
      @tasks_by_state[tt.task.state] << tt
    end
  end
end
