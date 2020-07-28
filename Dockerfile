FROM debian:buster-slim
LABEL maintainer="Andrew Fried <afried@deteque.com>"
ENV VERSION 20200611.1
ENV UNBOUND_VERSION=1.11.0

RUN 	mkdir -p /etc/unbound/zonefiles \
	&& chmod 1777 /etc/unbound \
	&& mkdir -p /root/scripts \
	&& mkdir -p /root/unbound \
	&& apt-get clean \
	&& apt-get update \
	&& apt-get -y dist-upgrade \
	&& apt-get -y autoclean \
	&& apt-get -y autoremove \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		apt-transport-https \
		build-essential \
		ca-certificates \
		dnstop \
		iftop \
		libexpat1-dev \
		libevent-dev \
		libssl-dev \
		lsb-release \
		locate \
		net-tools\
		procps \
		rsync \
		sipcalc \
		vim \
		wget \
        && useradd unbound -s /bin/false -d /nonexistent -M -U \
	&& ldconfig \
	&& sync \
	&& updatedb

WORKDIR /tmp
RUN	wget -O /tmp/unbound-${UNBOUND_VERSION}.tar.gz https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz \
 	&& tar -zxvf unbound-${UNBOUND_VERSION}.tar.gz

WORKDIR /tmp/unbound-${UNBOUND_VERSION}
RUN 	./configure \
	--prefix=/usr \
	--mandir=/usr/share/man \
	--sysconfdir=/etc \
	--with-libevent \
	&& make \
	&& make install 

COPY	scripts /root/scripts
COPY	unbound.conf /root/unbound/unbound.conf
COPY	unbound.conf.FULL /root/unbound/unbound.conf.DISTRIBUTION

WORKDIR /etc/unbound

EXPOSE 53/tcp
EXPOSE 53/udp

VOLUME [ "/etc/unbound" ]
VOLUME [ "/etc/letsencrypt" ]

CMD [ "/usr/sbin/unbound","-c","/etc/unbound/unbound.conf" ]
