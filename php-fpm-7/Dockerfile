FROM ubuntu:16.04 

RUN apt-get update && apt-get install -y rsync php php-fpm php-xml \
    php-curl php-imagick php-gd php-mysqli php-readline php-memcached \
    php-memcache php-redis php-sockets \
    imagemagick-common imagemagick \
    --no-install-recommends && rm -r /var/lib/apt/lists/* &&\
    mkdir /run/php 
    
COPY html/ /var/www/html

RUN chown -R www-data:www-data /var/www/html

COPY php.ini /etc/php/7.0/fpm/php.ini
COPY www.conf /etc/php/7.0/fpm/php-fpm.conf
COPY www.conf /etc/php/7.0/fpm/pool.d/www.conf

CMD ["php-fpm7.0"]
