# Developer Documentation

This guide explains how to set up, build, run and maintain the Inception stack from scratch. For day-to-day usage, see [USER_DOC.md](USER_DOC.md).

## 1. Set up the environment from scratch

### Prerequisites

- A Linux virtual machine (Debian 12 recommended).
- `docker` and the `docker compose` plugin.
- `make` and `git`.
- Your user in the `docker` group, so Docker runs without `sudo`:

```bash
sudo usermod -aG docker $USER
```

Log out and back in (or reboot) for the change to apply. Check with `groups` and `docker ps`.

### Get the project

```bash
git clone <repository-url> ~/inception
cd ~/inception
```

### Domain name

The domain must resolve to the local machine:

```bash
echo "127.0.0.1 aosset-o.42.fr" | sudo tee -a /etc/hosts
```

### Configuration file (`srcs/.env`)

`srcs/.env` is not versioned (it is listed in `.gitignore`), so you must create it:

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

Rules:

- No spaces around `=` and no quotes.
- Never commit this file.
- The variables are read by `init.sh` (MariaDB) and `setup.sh` (WordPress). A missing or misspelled variable reaches the script empty and makes it fail.

### Credentials and secrets

Credentials are currently provided through environment variables from `.env`. They are applied only on the first start, when the database and WordPress are initialised. To move to Docker secrets, declare a top-level `secrets:` section in `docker-compose.yml`, mount them in the services and read `/run/secrets/<name>` from the scripts.

## 2. Build and launch

### Project layout

```
.
├── Makefile
└── srcs/
    ├──
