# Installation Instructions

1. Install Homebrew: https://brew.sh/
2. `brew install git`
   * `git clone` the project directory into a folder called `imageviewer`
3. Install RMV: https://rvm.io/rvm/install
	 * `rvm install 2.0.0`
	 * `rvm use 2.0.0`, you may also want to set the default at this time
	 * `gem install bundler` to be able to use Gemfile for installation
	 * `cd project_directory && bundle install` to install Rails and all gems
4. `brew install postgres` We use Postgres for our DB
	 * `brew services start postgres`
	 * DEVELOPMENT ONLY: Install PSequel http://www.psequel.com/
5. `brew install python3` We use python for conversion and heavy scripts
6. `brew install openslide` We use openslide for file conversions
7. `brew install redis` We use redis for Sidekiq/background workers
	 * `brew services start redis`
8. Follow the AWS Installation instructions here: http://docs.aws.amazon.com/cli/latest/userguide/cli-install-macos.html
	 * Afterwards, run `aws configure` and talk to Alice for AWS Credentials
9. DEVELOPMENT ONLY `pip install virtualenv`  
	 * `cd /yourpath/imageviewer/python`
	 * `virtualenv --system-site-packages -p python3 env`
	 * `source env/bin/activate`

## Test out that you can start the rails server
* `cd /yourpath/imageviewer && rails s`
* Navigate to localhost:3000 in your browser

## Test out that openslide works: 
* `cd /yourpath/imageviewer/python`
* `mkdir data`
* Put some svs data into this /data folder
* `python3 deepzoom_tile.py data/NAMEOFSVSHERE.svs`
* It should run and generate a folder called NAMEOFSVSHERE_files with tiled images in your data folder
