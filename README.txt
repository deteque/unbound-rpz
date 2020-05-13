Utilities:

unbound-conrol:	Manages unbound daemon (like rndc)
unbound-checkconf: Checks unbound.conf file for errors
unbound-anchor:	Creates DNSSEC key
unbound-control-setup:	Generates keys for remote control

To update the root cache:
/usr/bin/wget --user=ftp --password=ftp ftp://ftp.rs.internic.net/domain/db.cache -O /etc/unbound/root.cache

CHANGES TO /etc/sysctl.conf:
###################################################################
# Changes to accomodate Unbound
###################################################################

net.core.rmem_max = 8388608 
net.core.wmem_max = 8388608 
net.ipv4.tcp_mem = 8388608 8388608 8388608
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 65536 8388608

