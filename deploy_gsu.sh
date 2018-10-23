git pull origin master
bundle install --without development test
RAILS_ENV=production rake db:migrate
RAILS_ENV=production rake assets:precompile
sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec passenger-config restart