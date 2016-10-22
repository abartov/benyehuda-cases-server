#!/bin/bash --login
. ~/.profile
rvm use 2.2
echo 'rvmdo.sh using RAILS_ENV=production (!!) and Ruby 2.2'
export RAILS_ENV=production 
$1
