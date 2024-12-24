# FEMP (FreeBSD, Nginx, MariaDB, and PHP(PHPMyAdmin))
## Now apply template to container
```sh
bastille create openssl 14.1-RELEASE YourIP-Bastille
bastille bootstrap https://github.com/bastille-templates/openssl
bastille template openssl bastille-templates/openssl
```

## License
This project is licensed under the BSD-3-Clause license.