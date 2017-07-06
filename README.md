# Installation Instructions

1. Install Homebrew: https://brew.sh/
2. `brew install git` or `yum install git`
   * `git clone` the project directory into a folder called `imageviewer`
3. Install RVM: https://rvm.io/rvm/install
	 * `source /home/ashen5/.rvm/scripts/rvm`
	 * `rvm install 2.0.0`
	 * `rvm use 2.0.0`, you may also want to set the default at this time
	 * `gem install bundler` to be able to use Gemfile for installation
	 * bower install and npm install
	 * `cd project_directory && bundle install` to install Rails and all gems (if you are having trouble installing pg 0.1 8.4, follow the instructions here: https://stackoverflow.com/questions/6040583/cant-find-the-libpq-fe-h-header-when-trying-to-install-pg-gem)
	 
4. We use Postgres for our DB
	 * `brew install postgres` or https://wiki.postgresql.org/wiki/PostgreSQL_on_RedHat_Linux
	 * `brew services start postgres` 
	 * DEVELOPMENT ONLY: Install PSequel http://www.psequel.com/
5. `brew install python3` or `yum install sudo yum install python34u python34u-wheel` We use python for conversion and heavy scripts
6. `brew install openslide` We use openslide for file conversions
7. `brew install redis` or `sudo yum install redis` We use redis for Sidekiq/background workers
	 * `brew services start redis` or `redis-server --daemonize yes`
8. `brew install nodejs` or `sudo yum install nodejs`
9. Follow the AWS Installation instructions here: http://docs.aws.amazon.com/cli/latest/userguide/cli-install-macos.html
	 * Afterwards, run `aws configure` and talk to Alice for AWS Credentials
10. DEVELOPMENT ONLY 
	 * If pip is not installed: `sudo yum install python-pip python-wheel`
	 * `pip install virtualenv`  
	 * `cd /yourpath/imageviewer/python`
	 * `virtualenv --system-site-packages -p python3 env`
	 * `source env/bin/activate`
	 * `pip install -r requirements.txt`

## Test out that you can start the rails server
* `cd /yourpath/imageviewer && rails s`
* Navigate to localhost:3000 in your browser

## Test out that openslide works: 
* `cd /yourpath/imageviewer/python`
* `mkdir data`
* Put some svs data into this /data folder
* `python3 deepzoom_tile.py data/NAMEOFSVSHERE.svs`
* It should run and generate a folder called NAMEOFSVSHERE_files with tiled images in your data folder
