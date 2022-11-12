FROM debian:bullseye-slim
LABEL maintainer="Andrew Fried <afried@deteque.com>"
ENV UNBOUND_VERSION 1.17.0
ENV BUILD_DATE 2022-11-12

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
		dh-autoreconf \
		dnstop \
		git \
		iftop \
		libexpat1-dev \
		libevent-dev \
		libssl-dev \
		lsb-release \
		locate \
		net-tools\
		php-cli \
		php-mysql \
		php-curl \
		pkg-config \
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
RUN	git clone --branch 21.x https://github.com/google/protobuf \
        && git clone https://github.com/protobuf-c/protobuf-c \
	&& wget -O /tmp/unbound-${UNBOUND_VERSION}.tar.gz https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz \
 	&& tar -zxvf unbound-${UNBOUND_VERSION}.tar.gz

WORKDIR /tmp/protobuf
RUN	autoreconf -i \
	&& ./configure \
	&& make \
	&& make install \
	&& ldconfig

WORKDIR /tmp/protobuf-c
RUN	autoreconf -i \
	&& ./configure \
	&& make \
	&&  make install

WORKDIR /tmp/unbound-${UNBOUND_VERSION}
RUN 	./configure \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--sysconfdir=/etc \
		--with-libevent \
		--enable-dnstap \
 	&& make \
 	&& make install \
 	&& ldconfig

COPY	scripts /root/scripts
COPY	sysctl.conf /root/unbound/sysctl.conf
COPY	root.cache /root/unbound/root.cache
COPY	unbound.conf /root/unbound/unbound.conf
COPY	unbound.conf.DISTRIBUTION_1.15.0 /root/unbound/unbound.conf.DISTRIBUTION_1.15.0

WORKDIR /etc/unbound

EXPOSE 53/tcp
EXPOSE 53/udp

VOLUME [ "/etc/unbound" ]
VOLUME [ "/etc/letsencrypt" ]

CMD [ "/usr/sbin/unbound","-c","/etc/unbound/unbound.conf" ]
