#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." 2>&1
  exit 1
fi

# Determine if we're running in EC2 or Vagrant.  Default will be EC2
if [ -d /home/vagrant ]; then
    TARGET_USER='vagrant'
    VAGRANT=true
    if [ -z "$1" ]; then
        echo "You must specify the security group when using Vagrant.  $0 WebSG | DBSG | MonitorSG | GoServerSG"
        exit 255
    fi
elif [ -d /home/ubuntu ]; then
    TARGET_USER='ubuntu'
    VAGRANT=false
else
    echo No vagrant user or ubuntu user found.  Are you in EC2 or Vagrant?
    exit 255
fi
HOME_TARGET="/home/$TARGET_USER"

DOWNLOAD_URL=http://thoughtworksinc.github.com/InfraTraining/files

cd /root

# common setup for all nodes, applied by cloud formation
apt-get update


# do something node specific based on the passed security group
if [ -n "$1" ]; then
    SECURITY_GROUP=$(echo $1 | cut -d- -f 2)
else
    SECURITY_GROUP=$(curl -s http://169.254.169.254/latest/meta-data/security-groups | cut -d- -f 2)
fi

function setup_puppet {
    if [[ -n $(which puppet) && -n $(which facter) ]]; then
	echo "already installed"
	return 0
    fi
    apt-get install -y ruby rubygems ruby-dev libruby libshadow-ruby1.8 libaugeas-ruby1.8

    rm -f facter-1.6.0.tar.gz
    wget http://puppetlabs.com/downloads/facter/facter-1.6.0.tar.gz
    tar zxvf facter-1.6.0.tar.gz
    cd facter-1.6.0
    ./install.rb --no-ri --no-rdoc --no-tests
    cd ..

    rm -f puppet-2.7.1.tar.gz
    wget http://puppetlabs.com/downloads/puppet/puppet-2.7.1.tar.gz
    tar zxvf puppet-2.7.1.tar.gz
    cd puppet-2.7.1
    ./install.rb --no-ri --no-rdoc --no-tests
    cd ..

    groupadd puppet
}

function setup_web {
    echo "nothing to do"
}

function setup_db {
    echo "nothing to do"
}

function setup_monitor {
    setup_puppet

    rm -f nagios.tgz
    wget $DOWNLOAD_URL/nagios.tgz
    tar zxvf nagios.tgz
    puppet apply --modulepath=modules nagios.pp

    rm -f cucumber.tgz
    wget $DOWNLOAD_URL/cucumber.tgz
    tar zxvf cucumber.tgz
    cp -r cucumber ${HOME_TARGET}
    chown -R $TARGET_USER:$TARGET_USER ${HOME_TARGET}/cucumber
    # Moved all this to bash temporarily.  Would normally be in Puppet too.
    # build-essential for native extensions in gems
    apt-get install --yes build-essential libxml2-dev libxslt-dev make
    gem install bundler
    cd ${HOME_TARGET}/cucumber
    bundle install
}

function setup_git {
    mkdir -p git-install
    cd git-install
    rm -f git.tgz
    wget $DOWNLOAD_URL/git.tgz
    tar zxvf git.tgz
    puppet apply --modulepath=modules git.pp
    cd ..
}

function setup_go {
    apt-get -y install python-pip
    pip install boto
    mkdir -p go-install
    cd go-install
    # rm -f go.tgz
    wget $DOWNLOAD_URL/go.tgz
    tar zxvf go.tgz
    puppet apply --modulepath=modules go.pp
    apt-get install --yes build-essential libxml2-dev libxslt-dev make
    gem install bundler
	gem install cucumber
    cd ..
}

case $SECURITY_GROUP in
    WebSG)
        setup_web
        ;;
    DBSG)
        setup_db
        ;;
    MonitorSG)
        setup_monitor
        ;;
    GoServerSG)
        setup_puppet
        setup_git
        setup_go
        ;;
esac
