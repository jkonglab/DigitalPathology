
# Install RVM and Ruby 2.5.1
    sudo yum update
    sudo yum install -y curl gpg gcc gcc-c++ make
    sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -sSL https://get.rvm.io | sudo bash -s stable
    sudo usermod -a -G rvm `whoami`
    rvm install ruby-2.5.1
    rvm --default use ruby-2.5.1

# Install other prerequisites
    sudo yum install -y redis git
    sudo yum install -y gtk-doc libxml2-devel libjpeg-turbo-devel libpng-devel libtiff-devel libexif-devel libgsf-devel lcms-devel ImageMagick-devel curl
    sudo yum install -y libwebp-devel
    sudo yum install -y vips vips-devel vips-tools


# Install Postgres and configure imageviewer user
    sudo yum install postgresql-server postgresql-contrib postgresql-devel
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
    
# Set up App Code & Install Gems
    cd /var/www
    git clone git@github.com:ays0110/imageviewer.git
    cd imageviewer
    gem install bundler
    bundle install

# Setup imageviewer user and permissions
    sudo adduser imageviewer
    sudo passwd imageviewer
    sudo groupadd webapp
    sudo usermod -a -G webapp `whoami`
    sudo usermod -a -G webapp imageviewer
    sudo mkdir /var/www
    chown -R `whoami`:webapp /var/www

# Set up Environmental Variables & DB
    su - imageviewer
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

Then run:
   
    RAILS_ENV=production bundle exec rake assets:precompile
    RAILS_ENV=production rake db:create
    RAILS_ENV=production rake db:migrate

# Create passenger config file
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

# Running passenger

To start passenger:

    sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec passenger start
    
To stop passenger:

    sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec passenger stop
    
To restart passenger:

    sudo /usr/local/rvm/gems/ruby-2.5.1/wrappers/bundle exec passenger-config restart

# Set up virtual envs for python

Install some basic requirements to do python scipy, numpy and scikit-learn

    yum install python3
    yum install scipy
    yum install numpy
    yum install gcc-gfortran
    yum install atlas-devel
    
Set up pip and virtualenv

    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo python get-pip.py
    rm get-pip.py
    sudo pip install -U virtualenv
    
Set up the first virtual environment in the /python folder:

    cd /imageviewer/python/conversion
    virtualenv --system-site-packages -p python3 ./env
    source env/bin/activate
    pip install -r requirements.txt

Set up the second virtual environment in the /algorithms/python3 folder:

    cd /imageviewer/algorithms/python3
    virtualenv --system-site-packages -p python3 ./env
    source env/bin/activate
    pip install -r requirements.txt
    

