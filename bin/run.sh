#!/bin/bash

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

# Migration stuff
if [ -d /data/apps ]; then
  echo "Migrate apps... (This will take some time...)"

  for DIR in $(find /data/apps ! -path /data/apps -type d -maxdepth 1); do
    DIR=${DIR##*/}

    # Delete apps that are delivered with Nextcloud
    if [ -d /opt/nextcloud/apps/$DIR ]; then
      rm -rf /data/apps/$DIR
    fi
  done

  if [ -d /data/userapps ]; then
    mv /data/apps/* /data/userapps/
    rm -rf /data/apps
  else
    mv /data/apps /data/userapps
  fi
fi

# Bootstrap application
echo "Preparing environment... (This will take some time...)"

if [ ! -d /data/config ]; then
  mkdir /data/config
fi

cp -f /opt/nextcloud/config/config.sample.php /data/config/
cp -f /opt/nextcloud/config/docker.config.php /data/config/

if [ ! -d /data/data ]; then
  mkdir /data/data
fi

if [ ! -d /data/tmp ]; then
  mkdir /data/tmp
fi

if [ ! -d /data/userapps ]; then
  mkdir /data/userapps
fi

rm -rf /opt/nextcloud/data /opt/nextcloud/config
ln -s /data/data /opt/nextcloud/
ln -s /data/config /opt/nextcloud/
ln -s /data/userapps /opt/nextcloud/

chown -R nobody:nobody /data /opt/nextcloud/config

echo "Starting supervisord..."

pid=0

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; term_handler' SIGTERM
trap 'kill ${!}; term_handler' INT

# run application
/usr/bin/supervisord -c /etc/supervisord.conf &
pid="$!"

# wait indefinetely
while true
do
  tail -f /dev/null & wait ${!}
done
