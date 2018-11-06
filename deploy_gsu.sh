git pull origin master
bundle install --without development test
RAILS_ENV=production rake db:migrate
RAILS_ENV=production rake assets:precompile
rvmsudo bundle exec passenger stop
rvmsudo bundle exec passenger start
bundle exec sidekiqctl stop tmp/sidekiq.pid
bundle exec sidekiq -d -L log/sidekiq.log -C config/sidekiq.yml -e production 