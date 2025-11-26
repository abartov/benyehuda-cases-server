# frozen_string_literal: true

# Whenever/Crontab tasks for Capistrano
namespace :whenever do
  desc 'Update the crontab'
  task :update do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec', 'whenever', '--update-crontab', fetch(:whenever_identifier)
        end
      end
    end
  end

  desc 'Clear the crontab'
  task :clear do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec', 'whenever', '--clear-crontab', fetch(:whenever_identifier)
        end
      end
    end
  end
end
