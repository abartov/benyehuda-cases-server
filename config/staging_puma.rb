app_dir = File.expand_path("../..", __FILE__)
rackup(File.expand_path('../config.ru', __dir__))
if ENV['RACK_ENV'] == 'production'
  require 'puma/daemon'
  environment 'production'
  workers Integer(1)
  daemonize
  shared_dir = "#{app_dir}/shared"
  bind "unix://#{shared_dir}/tmp/sockets/puma.sock"
  stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true
else
  workers 0
  environment 'development'
  shared_dir = "#{app_dir}"
end

threads_count = Integer(1)
threads 1, threads_count

preload_app!

# port        ENV['PORT']     || 3000
stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true
pidfile "#{shared_dir}/tmp/pids/puma.pid"


