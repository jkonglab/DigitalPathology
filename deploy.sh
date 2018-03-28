git pull origin master
bundle install --without development test
RAILS_ENV=production rake db:migrate
RAILS_ENV=production rake assets:precompile
sudo /usr/local/bin/restartapache