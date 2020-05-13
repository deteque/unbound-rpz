#!/bin/sh
/usr/sbin/unbound-anchor
/usr/sbin/unbound-control-setup
/usr/bin/wget --user=ftp --password=ftp ftp://ftp.rs.internic.net/domain/db.cache -O /etc/unbound/root.cache
