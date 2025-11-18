class DedupeTeams < ActiveRecord::Migration[6.1]
  def change
    # iterate over all teams and de-duplicate memberships and tasks
    print "de-duplicating #{Team.count} teams... "
    Team.all.each do |team|
      # de-duplicate team memberships
      team.team_memberships.group_by(&:user_id).each do |user_id, memberships|
        memberships.shift
        memberships.each(&:destroy)
      end

      # de-duplicate task teams
      team.task_teams.group_by(&:task_id).each do |task_id, task_teams|
        task_teams.shift
        task_teams.each(&:destroy)
      end
    end
    puts 'done!'
  end
end
