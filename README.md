# Nextcloud docker image

![](https://s32.postimg.org/69nev7aol/Nextcloud_logo.png)

Easy usable docker image for [Nextcloud](http://nextcloud.com), the community fork of OwnCloud.

## Features

* Uses latest stable version of **Alpine Linux**, bundled with **PHP 5** and **NGinx**.
* GPG check during build process.
* APCu already configured.
* LDAP support.
* Cron running all 15 mins (No need for web or AJAX cron).
* Persistence for data, configuration and apps.
* Nextcloud included apps that are persistent will be automatically updated during start.
* Working with MySQL/MariaDB (server not included).
* Supports uploads up to 10GB.

## Container environment

### Included software

* Alpine Linux 3.4 (stable)
* PHP 5
* APCu
* NGinx
* cron
* rsync
* SupervisorD

Everything is bundled in the newest stable version.

### Tags

* **latest**: latest stable Nextcloud version
* **vX.X.X**: stable version tags of Nextcloud (e.g. v9.0.52)

### Build-time arguments
* **NEXTCLOUD_GPG**: Fingerprint of Nextcloud signing key
* **NEXTCLOUD_VERSION**: Nextcloud version to install

### Exposed ports
- **80**: NGinx webserver running Nextcloud.

### Volumes
- **/data** : All data, including config and apps (in subfolders).

## Usage

### Standalone

You can run Nextcloud without a separate database, but it's not recommended for production setups as it uses SQLite. Another solution is to use an external database provided elsewhere, you can enter the credentials in the installer.

1. Pull the image: `docker pull rootlogin/nextcloud`
2. Run it: `docker run -d --name nextcloud -p 80:80 -v my_local_data_folder:/data rootlogin/nextcloud` (Replace *my_local_data_folder* with the path where do you want to store the persistent data)
3. Open [localhost](http://localhost) and profit!

If it's the first you run this, you can use the Nextcloud setup wizard to install everything. Afterwards it will run directly.

### With a database container

For standard setups I recommend the use of MariaDB, because it's more reliable than SQLite. As example, you can use the offical docker image of MariaDB for doing that. For more information refer to the according docker image.

```
# docker pull rootlogin/nextcloud && docker pull mariadb:10
# docker run -d --name nextcloud_db -v my_db_persistence_folder:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=supersecretpassword -e MYSQL_DATABASE=nextcloud -e MYSQL_USER=nextcloud -e MYSQL_PASSWORD=supersecretpassword mariadb:10
# docker run -d --name nextcloud --link nextcloud_db:nextcloud_db -v my_local_data_folder:/data rootlogin/nextcloud
```

*The auto-connection of the database to nextcloud is not implemented yet. So you need to do that manually at the moment.*

## Configuration

You can configure Nextcloud via the occ command:

```
# docker exec -ti nextcloud occ [...YOUR COMMANDS...]
```

This automatically runs as the user of the webserver.

## Other

### Migrate from OwnCloud

You can easily migrate an existing OwnCloud to this Nextcloud docker image.

**But before starting, always make a backup of your old OwnCloud instance. I told you so!**

1. Enable the maintenance mode on your old OwnCloud instance, e.g. `sudo -u www-data ./occ maintenance:mode --on`
2. Create a new folder e.g. /var/my_nextcloud_data
3. In this folder create a new subfolder called "config" and copy the config.php from your existing instance in there.
4. Copy your existing "data" folder to */var/my_nextcloud_data*/data
5. Start the docker container: `docker run -d --name nextcloud -p 80:80 -v /var/my_nextcloud_data:/data rootlogin/nextcloud`
6. Wait until everything is running.
7. Start the Nextcloud migration command: `docker exec nextcloud occ upgrade`
8. Disable the maintenance mode of Nextcloud: `docker exec nextcloud occ maintenance:mode --off`
9. **Profit!** 

### Run container with systemd

I usually run my containers on behalf of systemd. For this I use the following config:

```
[Unit]
Description=Docker - Nextcloud container
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run -p 127.0.0.1:8000:80 -v /data/nextcloud:/data --name nextcloud rootlogin/nextcloud
ExecStop=/usr/bin/docker stop -t 2 nextcloud ; /usr/bin/docker rm -f nextcloud

[Install]
WantedBy=default.target
```

### NGinx frontend proxy

This container does not support SSL or anything and is therefor not made for running directly in the world wide web. For that you normaly use a frontend proxy like NGinx.

Here is some sample config (This config will not work as-is. But you can adapt it.):

```
server {
	listen 80;
	server_name cloud.example.net;

	# ACME handling for Letsencrypt
	location /.well-known/acme-challenge {
    	alias /var/www/letsencrypt/;
    	default_type "text/plain";
   		try_files $uri =404;
	}

	location / {
    	return 301 https://$host$request_uri;
	}
}

server {
        listen 443 ssl spdy;
        server_name cloud.example.net;

		ssl_certificate /etc/letsencrypt.sh/certs/cloud.example.net/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt.sh/certs/cloud.example.net/privkey.pem;
        ssl_trusted_certificate /etc/letsencrypt.sh/certs/cloud.example.net/chain.pem;
		ssl_dhparam /etc/nginx/dhparam.pem;
		ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

		ssl_session_cache shared:SSL:10m;
		ssl_session_timeout 30m;

		ssl_prefer_server_ciphers on;
		ssl_ciphers "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";

		ssl_stapling on;
		ssl_stapling_verify on;

		add_header Strict-Transport-Security "max-age=31536000";

		access_log  /var/log/nginx/docker-nextcloud_access.log;
        error_log   /var/log/nginx/docker-nextcloud_error.log;
	
		location / {
                proxy_buffers 16 4k;
                proxy_buffer_size 2k;

                proxy_read_timeout 300;
                proxy_connect_timeout 300;
                proxy_redirect     off;

                proxy_set_header   Host              $http_host;
                proxy_set_header   X-Real-IP         $remote_addr;
                proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
                proxy_set_header   X-Frame-Options   SAMEORIGIN;
                
                client_max_body_size 10G;

                proxy_pass http://127.0.0.1:8000;
        }
}
```

## Frequently Asked Questions

**Why does the start take so long?**

When you run the container it will sync the Nextcloud bundled apps with your persistent data folder. If Nextcloud was updated or runs the first time it will have to sync much data.

## Contribution

This stuff is released under GPL. I'm happy about every pull-request, that makes this tool better.