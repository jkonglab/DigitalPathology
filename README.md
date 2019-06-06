
# Set Up Libraries and Machine

## Install RVM and Ruby 2.5.1
    sudo yum update
    sudo yum install -y curl gpg gcc gcc-c++ make
    sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -sSL https://get.rvm.io | sudo bash -s stable
    sudo usermod -a -G rvm `whoami`
    rvm install ruby-2.5.1
    rvm --default use ruby-2.5.1

## Install other prerequisites
    sudo yum install -y redis git
    sudo yum install -y gtk-doc libxml2-devel libjpeg-turbo-devel libpng-devel libtiff-devel libexif-devel libgsf-devel lcms-devel ImageMagick-devel curl
    sudo yum install -y libwebp-devel
    sudo yum install -y vips vips-devel vips-tools

Or for Ubuntu:

    sudo apt-get install -y redis git
    sudo apt-get install -y gtk-doc-tools libxml2-dev libjpeg-dev libpng-dev libtiff-dev libexif-dev libgsf-1-dev liblcms2-dev imagemagick curl libwebp-dev
    sudo apt-get install -y libvips libvips-dev libvips-tools

# Setting up PostreSQL

## Install Postgres and configure imageviewer user
    sudo yum install postgresql-server postgresql-contrib postgresql-devel

Or for Ubuntu:

    sudo apt-get install postgresql postgresql-contrib libpq-dev
    
    sudo postgresql-setup initdb
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    sudo passwd postgres
    su - postgres
    psql -d template1 -c "ALTER USER postgres WITH PASSWORD 'MY_PASSWORD_HERE';"
    psql -d template1 -c "CREATE USER imageviewer WITH PASSWORD 'MY_PASSWORD_HERE';"
    psql -d template1 -c "ALTER USER imageviewer WITH SUPERUSER;"
    

## Setup Postgres to use passwords instead of ident
In pg_hba.conf, change all occurances of "ident" to "password"
    
    su - postgres
    cd /var/lib/pgsql/data
    vim pg_hba.conf
    sudo systemctl restart postgresql
    exit
    
    su - postgres
    cd /etc/lib/postgresql/##/main   
    vim pg_hba.conf
    logout
    sudo systemctl restart postgresql
    
# Setting up the Application 
## Set up App Code & Install Gems
    cd /var/www
    git clone http://github.com/ays0110/imageviewer
    cd imageviewer
    gem install bundler
    bundle install

## Setup imageviewer user and permissions
    sudo adduser imageviewer
    sudo passwd imageviewer
    sudo groupadd webapp
    sudo usermod -a -G webapp `whoami`
    sudo usermod -a -G webapp imageviewer
    sudo mkdir /var/www
    chown -R `whoami`:webapp /var/www

## Set up Environmental Variables & DB
    cd /var/www/imageviewer
    rake secret
    touch .env
    vim .env

In the file `.env` have:
    
    SECRET_KEY_BASE=SECRET_GENERATED_BY_RAKE_ABOVE
    DATABASE_USERNAME=imageviewer
    DATABASE_PASSWORD=MY_PASSWORD_HERE
    DATABASE_HOST=localhost
    RACK_ENV=production
    RAILS_ENV=production
    EMAIL_HOST=URL_OF_YOUR_APP_HERE
    
    # ONLY IF LOCAL VERSION!
    LOCAL_PROCESSING=true 

Then run: 
(for development, if setting up imageviewer user was skipped, you may need to set /var/www to chmod 777 in order to proceed)
   
    RAILS_ENV=production bundle exec rake assets:precompile
    RAILS_ENV=production rake db:create
    RAILS_ENV=production rake db:migrate

# Serve the Application

## Create passenger config file
    cd /imageviewer
    vim Passengerfile.json
    
    {
        // Run the app in a production environment. The default value is "development".
        "environment": "production",
        // Run Passenger on port 80, the standard HTTP port.
        "port": 80,
        // Tell Passenger to daemonize into the background.
        "daemonize": true,
    }

## Running passenger

To start passenger:

    sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec passenger start
    
To stop passenger:

    sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec passenger stop
    
To restart passenger:

    sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec passenger-config restart

## Set up virtual envs for python

Install some basic requirements to do python scipy, numpy and scikit-learn

    yum install python3
    yum install python3-dev
    yum install scipy
    yum install numpy
    yum install gcc-gfortran
    yum install atlas-devel
    
Or for Ubuntu:

    sudo apt-get install python3
    sudo apt-get install python3-dev
    sudo apt-get install python-scipy
    sudo apt-get install python-numpy
    sudo apt-get install gfortran
    sudo apt-get install libatlas-base-dev
    sudo apt-get install libopenslide-dev
    
Set up pip and virtualenv

    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo python get-pip.py
    rm get-pip.py
    sudo pip install -U virtualenv
    
Set up the first virtual environment in the /python folder:

    cd /imageviewer/python/conversion
    virtualenv -p python3 ./env
    source env/bin/activate
    pip install -r requirements.txt

Set up the second virtual environment in the /algorithms/python3 folder:

    cd /imageviewer/algorithms/python3
    virtualenv -p python3 ./env
    source env/bin/activate

(Due to a foolish scipy bug, you may need to run `pip install numpy` before running pip install -r requirements.txt)

    pip install -r requirements.txt
    
    
# Confirming Functionality

## Start up sidekiq and the server

    sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec passenger-config restart
    bundle exec sidekiqctl stop tmp/sidekiq.pid
    bundle exec sidekiq -d -L log/sidekiq.log -C config/sidekiq.yml -e production

## Create a user
1.) Go to your URL, whether that's a production URL like dp.gsu.edu or localhost:80, and sign up a new user.
2.) The app will send a confirmation email to the email that you signed up with.  
3.) Click the confirmation link to confirm the account.  Please note that the link will default to https://dp.gsu.edu, so if you are signing up a localhost account, simply change the url from http://dp.gsu.edu to localhost:80.

## Make that user an admin
Open up your terminal and cd into your imageviewer folder.  Then run `RAILS_ENV=production bundle exec rails c`
Inside the interactive rails session, run the following lines:

    a = User.first
    a.admin = 10
    a.save
    
## Log in and upload a new image
1.) Log in with the account you just made
2.) Navigate to /sidekiq and confirm that you can access this page.  If you can't, something bad happened in the admin stage above, and you should retry that
3.) Create a new project and upload an image. 
4.) After the image is uploaded, a job should appear in the sidekiq monitoring page /sidekiq.  Make sure it runs successfully.

## Troubleshooting a broken upload
1.) If you are on a local machine, do you have LOCAL_PROCESSING=true in your .env file?
2.) Restart sidekiq and the app server using the following commands

To restart Sidekiq:

    bundle exec sidekiqctl stop tmp/sidekiq.pid
    bundle exec sidekiq -d -L log/sidekiq.log -C config/sidekiq.yml -e production
    
To restart the server:

    sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec passenger stop
    sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec passenger start

    

    

