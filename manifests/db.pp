## Magic for forcing apt-get update to run before any package commands...
# This also where you'd configure the use of an apt cache
file { "/etc/apt/apt.conf.d/15update-stamp":
  ensure => present,
  content => "APT::Update::Post-Invoke-Success {\"touch /var/lib/apt/periodic/update-success-stamp 2>/dev/null || true\";};",
}

exec {"apt-get update":
  unless => "/usr/bin/test $(expr `date +%s` - `stat -c %Y /var/lib/apt/periodic/update-success-stamp`) -le 3600",
  command => "/usr/bin/apt-get update",
  require => File["/etc/apt/apt.conf.d/15update-stamp"]
}
Exec["apt-get update"] -> Package <||>
## end of magic

class mysql {
  package { "mysql-server":
    ensure => installed,
  }

  file {"/etc/mysql/conf.d/allow_external.cnf":
    owner =>  mysql,
    group =>  mysql,
    mode  =>  0644,
    content =>  template("/vagrant/allow_external.cnf"),
    require => Package["mysql-server"],
    notify => Service["mysql"],
  }

  service { "mysql":
    ensure  =>  running,
    enable  => true,
    hasstatus => true,
    hasrestart  => true,
    require =>  Package["mysql-server"],
  }
}

include mysql

define setupdb($db, $username, $password) {

  exec {"create-db-$db":
    unless  => "mysqlshow -uroot $db",
    command => "mysqladmin -uroot create $db",
    path => "/usr/bin/",
    require => Class["mysql"],
  }

  exec {"create-db-user-$db-$username":
    unless  => "mysqlshow -u$username -p$password $db",
    command => "mysql -uroot -e \"grant all on $db.* to '$username'@'%' identified by '$password'; grant all on $db.* to '$username'@'localhost' identified by '$password';\"",
    path => "/usr/bin/",
    require => Exec["create-db-$db"],
  }

}

setupdb {"opencart-db":
    db  =>  "opencart",
    username  =>  "opencart",
    password  =>  "openpass",
}
