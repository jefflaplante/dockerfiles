FROM php:7.0.13-fpm-alpine
RUN apk add --no-cache gd freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev && \
  docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  docker-php-ext-install -j${NPROC} gd && \
  docker-php-ext-install -j${NPROC} mysqli && \
  docker-php-ext-install -j${NPROC} sockets && \
  apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev
MAINTAINER Jeff LaPlante <jeff@jefflaplante.com>

