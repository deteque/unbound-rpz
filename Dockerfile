FROM debian:bookworm-slim
LABEL maintainer="Deteque <admin-deteque@spamhaus.com>"
ENV UNBOUND_VERSION 1.21.0
ENV BUILD_DATE "2024-08-29"

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
		bison \
		build-essential \
		ca-certificates \
		dh-autoreconf \
		dnstop \
		flex \
		git \
		iftop \
		libexpat1-dev \
		libevent-dev \
		libfstrm-dev \
		libprotobuf-dev \
		libprotobuf-c-dev \
		libssl-dev \
		lsb-release \
		locate \
		net-tools\
		php-cli \
		php-mysql \
		php-curl \
		pkg-config \
		procps \
		protobuf-c-compiler \
		rsync \
		sipcalc \
		vim \
		wget \
        && useradd unbound -s /bin/false -d /nonexistent -M -U \
	&& ldconfig \
	&& sync \
	&& updatedb

WORKDIR /tmp/
RUN /usr/bin/wget https://www.nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz \
	&& tar zxvf unbound-${UNBOUND_VERSION}.tar.gz

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

WORKDIR /etc/unbound

EXPOSE 53/tcp
EXPOSE 53/udp

VOLUME [ "/etc/unbound" ]
CMD [ "/usr/sbin/unbound","-c","/etc/unbound/unbound.conf" ]
