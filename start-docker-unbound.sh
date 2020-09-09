#!/bin/sh
mkdir -p /etc/unbound/zonefiles
/usr/bin/docker run \
	--rm \
	--detach \
	--name unbound-rpz \
	--publish 53:53 \
	--publish 53:53/udp \
	--volume /etc/unbound:/etc/unbound \
	deteque/unbound-rpz
