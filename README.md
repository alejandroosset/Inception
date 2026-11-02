*This project has been created as part of the 42 curriculum by aosset-o.*

# Inception

## Description

Inception is a system administration project whose goal is to build a small web infrastructure using **Docker** and **Docker Compose**, running inside a virtual machine. Every service runs in its own container, built from a custom Dockerfile based on **Debian 12 (bookworm)**. No pre-built service images (such as the official `nginx` or `wordpress` images) are used.

The stack is made of three services:

| Service | Role | Exposed to the host |
|---|---|---|
| **NGINX** | Reverse proxy and the only entry point. Serves HTTPS with TLS 1.2/1.3 | Port 443 |
| **WordPress + PHP-FPM** | The website and its administration panel | No (internal port 9000) |
| **MariaDB** | Database used by WordPress | No (internal port 3306) |

The website is reachable at `https://aosset-o.42.fr`.

### Project description

#### Use of Docker and included sources

Docker packages each service with its dependencies into an isolated, reproducible container. Docker Compose describes the whole stack (services, network, volumes and variables) in a single file and starts it with one command.

Sources included in the repository:

```
.
├── Makefile                      # Entry point: build, start, stop and clean
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs/
    ├── docker-compose.yml        # Services, network and volumes
    ├── .env                      # Variables and credentials (NOT versioned)
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/inception.conf     # HTTPS server and PHP forwarding
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf           # PHP-FPM listening on port 9000
        │   └── tools/setup.sh          # Installs WordPress with WP-CLI on first run
        └── mariadb/
            ├── Dockerfile
            ├── conf/99-inception.cnf   # MariaDB listens on all interfaces
            └── tools/init.sh           # Creates database and user on first run
```

#### Main design choices

- **One service per container**, each with its own Dockerfile and a foreground main process (`nginx -g "daemon off;"`, `php-fpm8.2 -F`, `mysqld`). No hacks like `sleep infinity` or `tail -f`.
- **NGINX is the only entry point**, on port 443 with TLS 1.2/1.3 and a self-signed certificate generated at build time. Port 80 is not served.
- **Initialisation scripts** run only the first time: `init.sh` creates the database and users, and `setup.sh` waits for MariaDB, downloads WordPress and creates two users (an administrator, whose name does not contain "admin", and a regular author).
- **Persistence** through two volumes stored on the host in `/home/aosset-o/data/`.
- **Containers restart automatically** (`restart: always`) if they crash.
- **Credentials are kept out of git**: `srcs/.env` is listed in `.gitignore`.

#### Comparisons

**Virtual Machines vs Docker**

| | Virtual Machine | Docker |
|---|---|---|
| Isolation | Full OS with its own kernel, isolated by a hypervisor | Processes isolated through kernel namespaces and cgroups, sharing the host kernel |
| Weight | Gigabytes, boots in minutes | Megabytes, starts in seconds |
| Performance | Overhead from virtualised hardware | Close to native |
| Portability | Heavy disk images | Small, reproducible images built from a Dockerfile |
| Typical use | Running a complete, different operating system | Packaging and deploying applications |

In this project a VM provides the isolated environment where Docker runs, and Docker packages each service.

**Secrets vs Environment Variables**

Environment variables are simple to use and are passed to the container at start (`env_file`), but they can be exposed through `docker inspect`, process listings or logs. Docker secrets are mounted as files in `/run/secrets/` inside the container, are not part of the image and are only visible to the services that need them, so they are the safer option for passwords. This project currently uses a `.env` file (excluded from git) for configuration and credentials, which is simple and enough for a local setup. For a production deployment, passwords should be moved to Docker secrets.

**Docker Network vs Host Network**

With the default `bridge` network used here (`inception`), containers get their own isolated network and talk to each other by service name (for example `wordpress:9000` or `mariadb:3306`). Only the ports explicitly published (`443`) are reachable from the host. With `network: host`, the container shares the host's network stack: there is no isolation, no port mapping and a higher risk of port conflicts. The subject forbids host networking, and the bridge network lets MariaDB and PHP-FPM stay unreachable from outside.

**Docker Volumes vs Bind Mounts**

A bind mount maps a specific host path into the container and depends on the host's directory structure. A Docker volume is created and managed by Docker, is easier to back up and migrate, and does not depend on the host layout. This project uses **named volumes** (`mariadb_data` and `wordpress_data`) configured with the `local` driver and `bind` options so that their data is physically stored in `/home/aosset-o/data/mariadb` and `/home/aosset-o/data/wordpress`, as required by the subject. NGINX mounts the WordPress volume read-only to serve the static files.

## Instructions

### Prerequisites

- A virtual machine running Debian 12 (or similar) with `docker`, `docker compose`, `make` and `git`.
- Your user must belong to the `docker` group.
- The domain must point to the local machine. Add this line to `/etc/hosts`:

```
127.0.0.1 aosset-o.42.fr
```

### Configuration

Create `srcs/.env` (it is not included in the repository) with the following variables, using your own passwords:

```
DOMAIN_NAME=aosset-o.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=<password>
MYSQL_ROOT_PASSWORD=<password>

WP_TITLE=Inception
WP_ADMIN_USER=<admin name, must not contain "admin">
WP_ADMIN_PASSWORD=<password>
WP_ADMIN_EMAIL=<email>

WP_USER=<regular user name>
WP_USER_PASSWORD=<password>
WP_USER_EMAIL=<email>
```

### Build and run

```bash
make          # create data folders, build images and start the stack
make down     # stop and remove the containers
make logs     # follow the logs
make re       # clean everything and rebuild from scratch
make fclean   # remove containers, images, volumes and data
```

### Access

- Website: `https://aosset-o.42.fr`
- Administration panel: `https://aosset-o.42.fr/wp-admin`

The browser will warn about the certificate because it is self-signed; this is expected.

More details are in [USER_DOC.md](USER_DOC.md) (usage) and [DEV_DOC.md](DEV_DOC.md) (development).

## Resources

### References

- [Docker documentation](https://docs.docker.com/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/) and [networking](https://docs.docker.com/engine/network/)
- [NGINX documentation](https://nginx.org/en/docs/) (SSL module and `fastcgi_pass`)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WordPress documentation](https://wordpress.org/documentation/) and [WP-CLI handbook](https://make.wordpress.org/cli/handbook/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [OpenSSL `req` manual](https://docs.openssl.org/master/man1/openssl-req/)

### Use of AI

Claude was used as a learning and debugging assistant. It was used for:

- Explaining Docker, Docker Compose, NGINX, TLS, PHP-FPM and MariaDB concepts.
- Helping to diagnose errors (typos in scripts, container restart loops, database connection problems, SSH/VM configuration).

All generated content was reviewed, typed, tested and debugged manually, and I can explain every part of the project.
