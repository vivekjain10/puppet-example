import "apt-magic"

package {"apache2":
    ensure  => installed
}

service {"apache2":
    ensure  => running,
    enable  =>  true,
    require =>  Package["apache2"],
}

package { ["php5-mysql", "php5-gd", "php5-curl"]:
    ensure  =>  installed,
    require =>  Package["php5"],
    notify  =>  Service["apache2"],
}

package { "php5":
    ensure  =>  installed,
    require =>  Package["apache2"],
    notify  =>  Service["apache2"],
}
