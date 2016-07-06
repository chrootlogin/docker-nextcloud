#!/bin/bash

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

echo "Starting environment..."

if [ ! -d /data/config ]; then
  mkdir /data/config
fi

if [ ! -f /data/config/config.sample.php ]; then
  cp /opt/nextcloud/config/config.sample.php /data/config/
fi

if [ ! -d /data/data ]; then
  mkdir /data/data
fi

if [ ! -d /data/apps ]; then
  mkdir /data/apps
fi

#for DIR in $(find /opt/nextcloud/apps ! -path /opt/nextcloud/apps -type d -maxdepth 1); do
#  DIR=${DIR##*/}

#  rsync -r --delete "/opt/nextcloud/apps/$DIR" /data/apps/
#done
rsync -r --delete /opt/nextcloud/apps/* /data/apps/

rm -rf /opt/nextcloud/data /opt/nextcloud/config /opt/nextcloud/apps
ln -s /data/data /opt/nextcloud/
ln -s /data/config /opt/nextcloud/
ln -s /data/apps /opt/nextcloud/

chown -R nobody:nobody /data /opt/nextcloud/config

touch /var/log/php-error.log
chown nobody:nobody /var/log/php-error.log

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
