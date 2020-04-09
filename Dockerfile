FROM php:5.5-fpm

COPY build/* /etc/apt/

RUN set -x \
  && DEBIAN_FRONTEND=noninteractive \
  && curl -fsSL https://download.newrelic.com/548C16BF.gpg | apt-key add - \
  && echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list \
  && apt-get update \
  # install required
  && apt-get install -y gnupg libicu-dev libmcrypt-dev libpng-dev apt-utils \
  # install memcached
  && apt-get install -y libmemcached-dev zlib1g-dev \
  && pecl install memcached-2.2.0 \
  && docker-php-ext-enable memcached \
  # install extensions
  && apt-get install -y libfreetype6-dev libjpeg62-turbo-dev \
  && docker-php-ext-install mbstring \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install gd bcmath intl mcrypt opcache \
  # install newrelic
  && apt-get install -y newrelic-php5 \
  && NR_INSTALL_SILENT=true newrelic-install install \
  && apt-get install -y nginx nscd \
  && apt-get clean \
  # configure newrelic
  && sed -i \
    -e "s/newrelic.appname =.*/newrelic.appname = \${NEW_RELIC_APP_NAME}/" \
    -e "s/newrelic.license =.*/newrelic.license = \${NEW_RELIC_LICENSE_KEY}/" \
    /usr/local/etc/php/conf.d/newrelic.ini \
  # configure php-fpm
  && rm -rf /usr/local/etc/php-fpm.d/*

EXPOSE 80

CMD service nginx start && service nscd start && php-fpm
