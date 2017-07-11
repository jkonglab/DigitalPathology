git pull origin master
cp custom-openseadragon-annotations.js node_modules/openseadragon-annotations/dist/openseadragon-annotations.js
RAILS_ENV=production rake db:migrate
RAILS_ENV=production rake assets:precompile
touch tmp/restart.txt
bundle exec sidekiq -d -L log/sidekiq.log -C config/sidekiq.yml -e production