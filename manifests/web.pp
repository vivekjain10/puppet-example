import "apt-magic"

package {"apache2":
    ensure  => installed
}

package { "php5":
    ensure  =>  installed,
    require =>  Package["apache2"],
}

package { ["php5-mysql", "php5-gd", "php5-curl"]:
    ensure  =>  installed,
    require =>  Package["php5"],
}