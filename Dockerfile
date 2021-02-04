FROM bitnami/minideb:buster

RUN \
  ## Docker User
  useradd -u 911 -U -d /var/www -s /bin/false xyz && \
  usermod -G users xyz && \
  ## Install Pre-reqs
  install_packages \
    apt-transport-https \
    ca-certificates \
    curl \
    lsb-release \
    nginx \
    unzip \
    cron \
    wget && \
  ## Install PHP APT Repository
  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php7.4.list && \
  ## Install PHP 7.4
  install_packages \
    php7.4 \
    php7.4-fpm \
    php7.4-gd \
    php7.4-curl \
    php7.4-zip \
    php7.4-mbstring \
    php7.4-xml \
    php7.4-intl && \

  ## Download GRAV
  mkdir -p \
    /grav && \
  GRAV_VERSION=$(curl -sX GET "https://api.github.com/repos/getgrav/grav/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
  curl -o /grav/grav.zip -L https://github.com/getgrav/grav/releases/download/${GRAV_VERSION}/grav-admin-v${GRAV_VERSION}.zip && \
  ## Setup cron to make control console green
  touch /var/spool/cron/crontabs/xyz && \
  (crontab -l; echo "* * * * * cd /var/www/grav;/usr/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -u xyz - && \
  chown xyz /var/spool/cron/crontabs/xyz && \
  ## Setup cron that really works
  (crontab -l; echo "* * * * * cd /var/www/grav;/usr/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab - && \
  ## Nginx Logs
  ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log

  # set recommended PHP.ini settings
  # see https://secure.php.net/manual/en/opcache.installation.php
  RUN { \
      echo 'opcache.memory_consumption=128'; \
      echo 'opcache.interned_strings_buffer=8'; \
      echo 'opcache.max_accelerated_files=4000'; \
      echo 'opcache.revalidate_freq=2'; \
      echo 'opcache.fast_shutdown=1'; \
      echo 'opcache.enable_cli=1'; \
      echo 'upload_max_filesize=128M'; \
      echo 'post_max_size=128M'; \
      echo 'expose_php=off'; \
      } > /usr/local/etc/php/conf.d/php-recommended.ini

EXPOSE 80 443

COPY root/ /

WORKDIR /var/www/grav

CMD ["/init-admin"]
