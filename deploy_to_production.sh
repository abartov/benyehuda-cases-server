echo "The deployment is a bit broken: it hangs after starting searchd remotely, and you have to manually kill searchd on the server for the deployment to continue. Later, it hangs after restarting Puma, and you need to manually stop and restart Puma to complete the deployment and cycle the releases. Yes, this should be fixed, ideally migrating to Capistrano."

RAILS_ENV=production bundle exec rake prod deploy
