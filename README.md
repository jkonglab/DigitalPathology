# Installation Instructions

1. Install Homebrew: https://brew.sh/ (if on OSX)
2. `brew install git` or `yum install git`
   * `git clone` the project directory into a folder called `imageviewer`
3. Install RVM: https://rvm.io/rvm/install
	 * `\curl -sSL https://get.rvm.io | bash -s stable`
	 * `rvm install 2.5.0`
	 * `rvm use 2.5.0`, you may also want to set it to the default at this time
	 * `gem install bundler` to be able to use Gemfile for installing gems in the future
	 * `cd project_directory && bundle install` to install Rails and all gems 
	   * if you are having trouble installing pg 0.1 8.4, follow the instructions here: https://stackoverflow.com/questions/6040583/cant-find-the-libpq-fe-h-header-when-trying-to-install-pg-gem
	 
4. We use Postgres for our DB, so install that:
	 * `brew install postgres` or https://wiki.postgresql.org/wiki/PostgreSQL_on_RedHat_Linux
	 * `brew services start postgres` or whatever command to start the postgres DB server
	 * DEVELOPMENT ONLY: Install PSequel http://www.psequel.com/
5. `brew install python3` or `sudo yum install python34u python34u-wheel python34-devel.x86_64 python34-setuptools` We use python for conversion and heavy scripts
6. `brew install openslide` or `yum install openslide` We use openslide for file conversions
7. `brew install redis` or `sudo yum install redis` We use redis for Sidekiq/background workers
	 * `brew services start redis` or `redis-server --daemonize yes`
8. `brew install nodejs` or `sudo yum install nodejs`
	 * Go back to the `/imageviewer` directory and run `npm install`
	 * Then `npm install -g bower`
	 * Then `bower install`
9. Pip comes installed with `brew install python`, but make sure `/usr/local/bin` is on your path 
	 * On CentOS: Install pip3 from python3 easy install (installed in step 5) to manage python libraries: `sudo easy_install-3.4 pip` (in following commands, use `pip3` install of `pip`
	 * `pip install virtualenv`  
	 * `cd /yourpath/imageviewer/python`
	 * `virtualenv --system-site-packages -p python3 env`
	 * `source env/bin/activate`
	 * `pip install -r requirements.txt`
11. Set up a `data` folder in your `/public` folder of your app
	* The name of this folder should match the data_directory config variable in your production.rb or development.rb
	* This folder is should not be tracked by git (add folder to .gitignore) and will contain all your uploads and converted data.
12. Set up a `run_data` folder in your `/algorithms` folder of your app
	* This folder is already in .gitignore and will not be tracked
13. Navigate to the root folder and run `npm install`

## Test out that you can start the rails server
* `rake db:create && rake db:migrate`
	* If you have trouble with something about "Cabbage", go to your database.yml file and change Cabbage to your computer's root name.
* `cd /yourpath/imageviewer && rails s`
* Open another window and type `sidekiq`
* Navigate to localhost:3000 in your browser

## Test out that openslide works: 
* `cd /yourpath/imageviewer/python`
* `mkdir data`
* Put some svs data into this /data folder
* `python3 deepzoom_tile.py data/NAMEOFSVSHERE.svs`
* It should run and generate a folder called NAMEOFSVSHERE_files with tiled images in your data folder

## Notes for production environments
* When deploying on production, run `sh deploy.sh` to do all the necessary prerequisite commands for a new deploy.
* Passenger Install & Setup Guides for CentOS
	* https://www.phusionpassenger.com/library/install/apache/install/oss/el7/ 
	* https://www.phusionpassenger.com/library/walkthroughs/deploy/ruby/ownserver/apache/oss/el7/deploy_app.html
* Postgres Setup for CentOS
	* Make Postgres use password authentication
	* Set up an app user and password for Postgres
	* Make sure you have database environmental variables exported for `DATABASE_USERNAME` and `DATABASE_PASSWORD`
* Make sure that redis and sidekiq are running so uploading/conversion works
	* `RAILS_ENV=production sidekiq`
	* May need to set up redis temp folder using `redis-cli` (https://stackoverflow.com/questions/19581059/misconf-redis-is-configured-to-save-rdb-snapshots)
