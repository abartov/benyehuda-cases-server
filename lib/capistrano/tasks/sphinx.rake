# frozen_string_literal: true

# Sphinx/ThinkingSphinx tasks for Capistrano
namespace :sphinx do
  desc 'Configure ThinkingSphinx'
  task :configure do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec', 'rake', 'ts:configure'
        end
      end
    end
  end

  desc 'Start searchd'
  task :start do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec', 'rake', 'ts:start'
        end
      end
    end
  end

  desc 'Stop searchd'
  task :stop do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec', 'rake', 'ts:stop'
        end
      end
    end
  end

  desc 'Restart searchd'
  task :restart do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec', 'rake', 'ts:restart'
        end
      end
    end
  end

  desc 'Index Sphinx'
  task :index do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec', 'rake', 'ts:index'
        end
      end
    end
  end

  desc 'Rebuild Sphinx (configure, stop, index, start)'
  task :rebuild do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec', 'rake', 'ts:rebuild'
        end
      end
    end
  end
end
