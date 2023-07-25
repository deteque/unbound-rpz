#!/bin/sh
mkdir -p /etc/unbound/zonefiles
/usr/bin/docker run \
	--rm \
	--detach \
	--name unbound-rpz \
	--network host \
	--volume /etc/unbound:/etc/unbound \
	deteque/unbound-rpz bash

