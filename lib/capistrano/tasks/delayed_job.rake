# frozen_string_literal: true

# Delayed Job tasks for Capistrano
namespace :delayed_job do
  desc 'Start delayed_job'
  task :start do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec', './script/delayed_job', 'start'
        end
      end
    end
  end

  desc 'Stop delayed_job'
  task :stop do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec', './script/delayed_job', 'stop'
        end
      end
    end
  end

  desc 'Restart delayed_job'
  task :restart do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          # Try to stop, but don't fail if it's not running
          begin
            execute :bundle, 'exec', './script/delayed_job', 'stop'
          rescue SSHKit::Command::Failed
            info 'delayed_job was not running, starting it now'
          end
          execute :bundle, 'exec', './script/delayed_job', 'start'
        end
      end
    end
  end
end
