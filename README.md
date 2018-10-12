
# Install RVM and Ruby 2.5.1
    sudo yum update
    sudo yum install -y curl gpg gcc gcc-c++ make
    sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -sSL https://get.rvm.io | sudo bash -s stable
    sudo usermod -a -G rvm `whoami`
    rvm install ruby-2.5.1
    rvm --default use ruby-2.5.1

# Install other prerequisites
    sudo yum install -y redis git epel-release
    sudo yum install -y --enablerepo=epel nodejs npm
    sudo yum install -y gtk-doc libxml2-devel libjpeg-turbo-devel libpng-devel libtiff-devel libexif-devel libgsf-devel lcms-devel ImageMagick-devel curl
    sudo yum install -y http://li.nux.ro/download/nux/dextop/el6/x86_64/nux-dextop-release-0-2.el6.nux.noarch.rpm
    sudo yum install -y --enablerepo=nux-dextop gobject-introspection-devel
    sudo yum install -y http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
    sudo yum install -y --enablerepo=remi libwebp-devel
    sudo yum install -y --enablerepo=remi vips vips-devel vips-tools


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
    export SECRET_KEY_BASE=SECRET_GENERATED_BY_RAKE_ABOVE
    export DATABASE_USERNAME=imageviewer
    export DATABASE_PASSWORD=MY_PASSWORD_HERE
    export DATABASE_HOST=localhost
    RAILS_ENV=production bundle exec rake assets:precompile
    RAILS_ENV=production rake db:create
    RAILS_ENV=production rake db:migrate



