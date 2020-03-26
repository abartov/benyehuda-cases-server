#!/bin/bash --login
. ~/.profile
rvm use 2.6
echo 'rvmdo.sh using RAILS_ENV=production (!!) and Ruby 2.6'
export RAILS_ENV=production
$1
