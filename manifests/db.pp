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
    require =>  Package["mysql-server"]
}

exec {"create-opencart-db":
    unless  => "mysqlshow -uroot opencart",
    command => "mysqladmin -uroot create opencart",
    path => "/usr/bin/",
    require => Service["mysql"],
}

exec {"grant-opencart-db":
    unless  => "mysqlshow -uopencart -popenpass opencart",
    command => "mysql -uroot -e \"grant all on opencart.* to 'opencart'@'%' identified by 'openpass'; grant all on opencart.* to 'opencart'@'localhost' identified by 'openpass';\"",
    path => "/usr/bin/",
    require => Exec["create-opencart-db"],
}
