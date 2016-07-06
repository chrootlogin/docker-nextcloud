FROM alpine:latest
MAINTAINER Simon Erhardt <hello@rootlogin.ch>

ENV NEXTCLOUD_GPG="2880 6A87 8AE4 23A2 8372  792E D758 99B9 A724 937A" \
  NEXTCLOUD_VERSION=9.0.52

RUN apk add --update \
  bash \
  gnupg \
  nginx \
  openssl \
  php5 \
  php5-apcu \
  php5-bz2 \
  php5-ctype \
  php5-curl \
  php5-dom \
  php5-exif \
  php5-fpm \
  php5-ftp \
  php5-gd \
  php5-gmp \
  php5-iconv \
  php5-intl \
  php5-json \
  php5-mcrypt \
  php5-openssl \
  php5-phar \
  php5-posix \
  php5-pdo_mysql \
  php5-pdo_sqlite \
  php5-sqlite3 \
  php5-xml \
  php5-xmlreader \
  php5-zip \
  php5-zlib \
  sudo \
  supervisor \
  tar \
  wget \
  && rm -rf /var/cache/apk/*

#RUN ln -sf /dev/stdout /var/log/nginx/access.log \
#  && ln -sf /dev/stderr /var/log/nginx/error.log
COPY bin/run.sh /bin/run.sh
COPY etc/supervisord.conf /etc/supervisord.conf
COPY etc/php-fpm.conf /etc/php5/php-fpm.conf
COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/fastcgi_params /etc/nginx/fastcgi_params
RUN chmod +x /bin/run.sh

VOLUME ["/data"]

RUN mkdir -p /opt/nextcloud

RUN NEXTCLOUD_TARBALL="nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" \
 && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL} \
 && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.sha256 \
 && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.asc \
 && wget -q https://nextcloud.com/nextcloud.asc \
 && echo "Verifying both integrity and authenticity of ${NEXTCLOUD_TARBALL}..." \
 && CHECKSUM_STATE=$(echo -n $(sha256sum -c ${NEXTCLOUD_TARBALL}.sha256) | tail -c 2) \
 && if [ "${CHECKSUM_STATE}" != "OK" ]; then echo "Warning! Checksum does not match!" && exit 1; fi \
 && gpg --import nextcloud.asc \
 && FINGERPRINT="$(LANG=C gpg --verify ${NEXTCLOUD_TARBALL}.asc ${NEXTCLOUD_TARBALL} 2>&1 \
  | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
 && if [ -z "${FINGERPRINT}" ]; then echo "Warning! Invalid GPG signature!" && exit 1; fi \
 && if [ "${FINGERPRINT}" != "${NEXTCLOUD_GPG}" ]; then echo "Warning! Wrong GPG fingerprint!" && exit 1; fi \
 && echo "All seems good, now unpacking ${NEXTCLOUD_TARBALL}..." \
 && tar xjf ${NEXTCLOUD_TARBALL} --strip-components=1 -C /opt/nextcloud \
 && rm -rf /tmp/* /root/.gnupg

EXPOSE 80
ENTRYPOINT ["/bin/run.sh"]
