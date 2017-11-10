git pull origin master
bundle install
RAILS_ENV=production rake db:migrate
bundle exec sidekiqctl stop tmp/sidekiq.pid
bundle exec sidekiq -d -L log/sidekiq.log -C config/sidekiq.yml -e production