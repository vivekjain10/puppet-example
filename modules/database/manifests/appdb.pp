define appdb($db, $username, $password) {

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

  file { "/root/$db.sql":
    content =>  template("database/root/$db.sql"),
  }

  exec {"load-$db-schema":
    command =>  "/usr/bin/mysql -u$username -p$password $db < /root/$db.sql",
    refreshonly =>  true,
    subscribe   =>  File["/root/$db.sql"],
    require =>  [Exec["create-db-user-$db-$username"], File["/root/$db.sql"]],
  }

}