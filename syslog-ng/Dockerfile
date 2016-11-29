FROM alpine:latest

MAINTAINER Jeff LaPlante <jeff.laplante@disney.com>

RUN apk --no-cache add syslog-ng 

EXPOSE 514/udp 

EXPOSE 601 

COPY syslog-ng.conf /etc/syslog-ng/syslog-ng.conf

CMD ["syslog-ng", "-F"]
