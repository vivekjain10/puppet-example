import "apt-magic"
import "webserver"

app {"app-opencart":
    db_host => "db",
    db_user => "opencart",
    db_password => "openpass",
    db_database => "opencart",
}