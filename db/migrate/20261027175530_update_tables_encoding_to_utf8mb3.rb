class UpdateTablesEncodingToUtf8mb3 < ActiveRecord::Migration[6.1]
  def change
    execute "ALTER TABLE api_users CONVERT TO CHARACTER SET utf8mb3 COLLATE utf8mb3_bin;"
    execute "ALTER TABLE audit_logs CONVERT TO CHARACTER SET utf8mb3 COLLATE utf8mb3_bin;"
    execute "ALTER TABLE task_idle_reminders CONVERT TO CHARACTER SET utf8mb3 COLLATE utf8mb3_bin;"
    execute "ALTER TABLE task_teams CONVERT TO CHARACTER SET utf8mb3 COLLATE utf8mb3_bin;"
    execute "ALTER TABLE team_memberships CONVERT TO CHARACTER SET utf8mb3 COLLATE utf8mb3_bin;"
    execute "ALTER TABLE teams CONVERT TO CHARACTER SET utf8mb3 COLLATE utf8mb3_bin;"
  end
end
