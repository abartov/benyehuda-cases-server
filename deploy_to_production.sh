echo "Currently, the deploy script hangs after starting the remote sphinx, and searchd needs to be killed by root on the server for the deployment to continue. Near the end of the deploy, it hangs after starting puma, and the production tasks puma needs to be killed by root on the server for the deployment to end. THEN the tasks system needs to be restarted manually."
echo "(yes, this very much needs to be fixed, ideally also switching to Capistrano)"

RAILS_ENV=production bundle exec rake prod deploy
