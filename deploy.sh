git pull origin master
RAILS_ENV=production rake db:migrate
RAILS_ENV=production rake assets:precompile
sudo /usr/local/bin/restartapache
bundle exec sidekiq -d -L log/sidekiq.log -C config/sidekiq.yml -e production