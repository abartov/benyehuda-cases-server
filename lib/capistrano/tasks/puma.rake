# frozen_string_literal: true

# Custom Puma management tasks for Capistrano
# This preserves the daemon mode used in the original vlad deployment
namespace :puma do
  desc 'Start Puma in daemon mode'
  task :start do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env), rack_env: fetch(:rails_env) do
          execute :bundle, 'exec', 'puma', '-C', 'config/puma.rb'
        end
      end
    end
  end

  desc 'Stop Puma'
  task :stop do
    on roles(:app) do
      within release_path do
        pid_file = "#{shared_path}/tmp/pids/puma.pid"
        if test("[ -f #{pid_file} ]")
          execute :kill, "-TERM $(cat #{pid_file})"
        else
          info 'Puma is not running (no pid file found)'
        end
      end
    end
  end

  desc 'Restart Puma'
  task :restart do
    on roles(:app) do
      within release_path do
        pid_file = "#{shared_path}/tmp/pids/puma.pid"
        if test("[ -f #{pid_file} ]")
          execute :kill, "-SIGUSR2 $(cat #{pid_file})"
        else
          info 'Puma is not running, starting it'
          invoke 'puma:start'
        end
      end
    end
  end

  desc 'Phased restart Puma (graceful restart with rolling workers)'
  task :phased_restart do
    on roles(:app) do
      within release_path do
        pid_file = "#{shared_path}/tmp/pids/puma.pid"
        if test("[ -f #{pid_file} ]")
          execute :kill, "-SIGUSR1 $(cat #{pid_file})"
        else
          info 'Puma is not running, starting it'
          invoke 'puma:start'
        end
      end
    end
  end

  desc 'Status of Puma'
  task :status do
    on roles(:app) do
      pid_file = "#{shared_path}/tmp/pids/puma.pid"
      if test("[ -f #{pid_file} ]")
        pid = capture(:cat, pid_file)
        if test("ps -p #{pid} > /dev/null")
          info "Puma is running with PID #{pid}"
        else
          info 'Puma pid file exists but process is not running'
        end
      else
        info 'Puma is not running (no pid file found)'
      end
    end
  end
end

# Hook puma restart into deploy
namespace :deploy do
  after :publishing, 'puma:restart'
end
