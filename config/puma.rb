app_dir = File.expand_path('..', __dir__)
shared_dir = app_dir
rackup(File.expand_path('../config.ru', __dir__))

if ENV['RACK_ENV'] == 'production' || ENV['RAILS_ENV'] == 'production'
  environment 'production'
  if Dir.pwd =~ /staging/
    workers 0
  else
    workers Integer(ENV['WEB_CONCURRENCY'] || 3)
  end
  pidfile "#{shared_dir}/tmp/pids/puma.pid"
  state_path "#{shared_dir}/tmp/pids/puma.state"
  bind "unix://#{shared_dir}/tmp/sockets/puma.sock"
  stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true
  # Note: daemonization is handled by systemd, not puma-daemon
else
  workers 0
  environment 'development'
end

threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads 1, threads_count

preload_app!
# port        ENV['PORT']     || 3000
