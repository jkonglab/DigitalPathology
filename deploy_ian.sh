git pull origin master
bundle install --without development test
bundle exec sidekiqctl stop tmp/sidekiq.pid
bundle exec sidekiq -d -L log/sidekiq.log -C config/sidekiq.yml -e production