define app($db_host, $db_user, $db_password, $db_database) {
  package { "wget":
    ensure  => "installed",
  }

  exec {"has-$db_database.deb":
    command =>  "/usr/bin/wget http://192.168.1.145/$db_database.deb -O /tmp/$db_database.deb",
    creates =>  "/tmp/$db_database.deb",
    require =>  Package["wget"],
  }

  file {"/etc/apache2/sites-enabled/000-default":
    ensure  =>  absent,
    notify  =>  Service["apache2"],
  }

  package{"$db_database":
    ensure    =>  latest,
    provider  =>  dpkg,
    source    =>  "/tmp/$db_database.deb",
    require   =>  [Exec["has-$db_database.deb"], Package["php5-mysql", "php5-gd", "php5-curl"]],
  }

  file{"/etc/apache2/sites-enabled/$db_database":
    ensure  =>  link,
    target  =>  "/etc/apache2/sites-available/$db_database",
    require =>  [Package["$db_database"], File["/etc/apache2/sites-enabled/000-default"]],
    notify  =>  Service["apache2"],
  }

  file { "/var/$db_database/config.php":
    content =>  template("webserver/var/$db_database/config.php"),
    owner   =>  www-data,
    group   =>  www-data,
    mode    =>  440,
    require =>  Package["$db_database"],
  }

}