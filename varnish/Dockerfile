FROM debian:wheezy 

MAINTAINER Jeff LaPlante <jeff.laplante@disney.com>

ENV VARNISH_CACHE_SIZE=256M

RUN apt-get -y update && apt-get -y install --no-install-recommends \
    ca-certificates \
    wget \
    varnish \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* 

COPY start.sh /start.sh

EXPOSE 6081 

CMD ["/start.sh"]

COPY default.vcl /etc/varnish/default.vcl
