#!/bin/bash --login
. ~/.profile
rvm use 3.2.1
pwd=`pwd`
if [[ $pwd =~ "staging" ]]
then
  echo Staging detected! Setting is_staging=true...
  export is_staging=true
fi
echo 'rvmdo.sh using RAILS_ENV=production (!!) and Ruby 3.2.1'
export RAILS_ENV=production
$1 $2 $3 $4 $5
