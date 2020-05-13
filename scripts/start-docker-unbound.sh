#!/bin/sh
/usr/bin/docker run \
docker run \
	--rm \
	--detach \
	--name unbound-rpz \
	--volume /etc/unbound:/etc/unbound \
	--publish 53:53 \
	--publish 53:53/udp \
	deteque/unbound-rpz
