# User Documentation

This guide explains how to use the Inception stack as an end user or administrator, without needing to know how it is built. For technical details, see [DEV_DOC.md](DEV_DOC.md).

## 1. Services provided

The stack runs three services, each in its own container:

| Service | What it does | Reachable from outside |
|---|---|---|
| **NGINX** | Web server. It receives all visitors over HTTPS (encrypted) and passes requests to WordPress. | Yes, port 443 only |
| **WordPress** | The website and its administration panel. | No, only through NGINX |
| **MariaDB** | The database where WordPress stores posts, pages and users. | No, internal only |

In short: you open the website in a browser, NGINX receives the request, WordPress builds the page and MariaDB provides the data.

## 2. Start and stop the project

All commands are run from the project root (the folder containing the `Makefile`), in a terminal on the virtual machine.

| Action | Command |
|---|---|
| Start everything (builds the first time) | `make` |
| Stop and remove the containers (data is kept) | `make down` |
| Pause the containers without removing them | `make stop` |
| Resume paused containers | `make start` |
| Follow the live logs | `make logs` |

The first start takes a few minutes because images are built and WordPress is installed. Later starts are much faster.

**Warning:** `make fclean` deletes containers, images **and all website data** (posts, users, uploads). Use it only to start from scratch.

## 3. Access the website and the administration panel

Before the first use, the domain name must point to the machine. On the machine where you open the browser, `/etc/hosts` must contain:

```
127.0.0.1 aosset-o.42.fr
```

Then open:

- **Website:** https://aosset-o.42.fr
- **Administration panel:** https://aosset-o.42.fr/wp-admin

The browser will show a security warning because the HTTPS certificate is self-signed (not issued by a public authority). This is expected: choose "Advanced" and continue to the site.

Plain `http://` (port 80) does not work by design. Always use `https://`.

## 4. Locate and manage credentials

All credentials are defined in one file:

```
srcs/.env
```

This file is **not stored in git**, so it exists only on the machine where the project runs. It contains:

| Variable | Meaning |
|---|---|
| `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD` | Administrator login for `/wp-admin` |
| `WP_USER` / `WP_USER_PASSWORD` | Regular user (author) login |
| `MYSQL_USER` / `MYSQL_PASSWORD` | Database user used by WordPress |
| `MYSQL_ROOT_PASSWORD` | Database root password |
| `DOMAIN_NAME` | Website domain |

To read a value: `cat srcs/.env`.

**Important rules:**

- **Do not share or commit** `srcs/.env`.
- Credentials are applied **only the first time** the stack starts. Editing `.env` afterwards does **not** change existing passwords.
- To change a WordPress password, use the admin panel (*Users → Profile*), or run `make fclean` and then `make` to rebuild everything with new values (this erases all data).

## 5. Check that the services are running correctly

**1. List the containers**

```bash
docker ps
```

Three containers should appear with status `Up`: `nginx`, `wordpress` and `mariadb`. Only NGINX should show a published port (`0.0.0.0:443->443/tcp`).

If a container shows `Restarting`, something is failing: see step 3.

**2. Check the website**

```bash
curl -k https://aosset-o.42.fr
```

It should return HTML from WordPress. In a browser, the site should load and you should be able to log in at `/wp-admin`.

**3. Look at the logs if something is wrong**

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

On the first start, `wordpress` may print `esperando MariaDB` for a few seconds. This is normal. A successful installation ends with `Success: WordPress installed successfully.`

**4. Check the database (optional)**

```bash
docker exec mariadb sh -c 'mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES;"'
```

The list should include `wordpress`.

## 6. Where the data is stored

Website and database data persist on the host machine, so they survive `make down` and restarts:

- `/home/aosset-o/data/wordpress` holds the WordPress files and uploads.
- `/home/aosset-o/data/mariadb` holds the database.

To back up the site, copy both folders while the stack is stopped (`make down`).

## 7. Quick troubleshooting

| Problem | Likely cause and fix |
|---|---|
| The browser cannot find `aosset-o.42.fr` | The line is missing in `/etc/hosts`. |
| Connection refused on port 443 | The stack is not running: run `make`, then `docker ps`. |
| Certificate warning | Expected with a self-signed certificate. Accept it. |
| Cannot log in as admin | Check the credentials in `srcs/.env`. |
| A container keeps restarting | Read `docker logs <name>`. |
