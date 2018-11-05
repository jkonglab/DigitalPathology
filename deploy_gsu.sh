git pull origin master
bundle install --without development test
RAILS_ENV=production rake db:migrate
RAILS_ENV=production rake assets:precompile
sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec passenger-config restart-app . --ignore-app-not-running --ignore-passenger-not-running
sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec sidekiqctl stop tmp/sidekiq.pid
sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec sidekiq -d -L log/sidekiq.log -C config/sidekiq.yml -e production 