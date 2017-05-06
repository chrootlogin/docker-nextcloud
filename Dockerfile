FROM alpine:edge
MAINTAINER Simon Erhardt <hello@rootlogin.ch>

ARG NEXTCLOUD_GPG="2880 6A87 8AE4 23A2 8372  792E D758 99B9 A724 937A"
ARG NEXTCLOUD_VERSION=11.0.3
ARG UID=1501
ARG GID=1501

RUN apk add --update \
  bash \
  gnupg \
  nginx \
  openssl \
  php7 \
  php7-apcu \
  php7-bz2 \
  php7-ctype \
  php7-curl \
  php7-dom \
  php7-exif \
  php7-fileinfo \
  php7-fpm \
  php7-ftp \
  php7-gd \
  php7-gmp \
  php7-iconv \
  php7-imap \
  php7-intl \
  php7-json \
  php7-ldap \
  php7-mcrypt \
  php7-mbstring \
  php7-openssl \
  php7-opcache \
  php7-pcntl \
  php7-phar \
  php7-posix \
  php7-pdo_mysql \
  php7-pdo_sqlite \
  php7-pdo_pgsql \
  php7-pgsql \
  php7-session \
  php7-simplexml \
  php7-sqlite3 \
  php7-xml \
  php7-xmlreader \
  php7-xmlwriter \
  php7-zip \
  php7-zlib \
  sudo \
  supervisor \
  tar \
  tini \
  wget \
  && rm -rf /var/cache/apk/* \
  && addgroup -g ${GID} nextcloud \
  && adduser -u ${UID} -h /opt/nextcloud -H -G nextcloud -s /sbin/nologin -D nextcloud \
  && mkdir -p /opt/nextcloud \
  && cd /tmp \
  && NEXTCLOUD_TARBALL="nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" \
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

COPY root /

RUN chmod +x /usr/local/bin/run.sh /usr/local/bin/occ /etc/periodic/15min/nextcloud

VOLUME ["/data"]

EXPOSE 80

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/run.sh"]
