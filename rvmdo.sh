#!/bin/bash --login
. ~/.profile
rvm use 1.9.3
echo RAILS_ENV=production  (!!)
export RAILS_ENV=production 
$1
