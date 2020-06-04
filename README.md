# unbound
Unbound Recursive DNS Server

# Installation
Create two directories on your server: "/etc/unbound" and "/etc/unbound/zonefiles".  The /etc/unbound directory will be primariy used to store log and configuraton files.  The /etc/unbound/zonefiles directory will be used to store the RPZ zonefiles.  The /etc/unbound directory will be bind mounted when the container is run.  You can create both directories by:

  mkdir -p /etc/unbound/zonefiles

A setup script will need to be run:

  docker run --rm -v /etc/unbound:/etc/unbound/ unbound-rpz /root/scripts/setup-unbound.sh

This will add keys for unbound-control and create the root.cache which is necessary for a recursive name server. The root.cache should be updated periodically by running:

  /usr/bin/wget --user=ftp --password=ftp ftp://ftp.rs.internic.net/domain/db.cache -O /etc/unbound/root.cache
  
# Create the unbound.conf file
The primary configuration file for unbound is unbound.conf. From within the container, a "mostly" configured unbound.conf can be found at /root/unbound/unbound.conf.  The sample file contains everything needed to get the dns server up and running except for the master IPs in the RPZ section as well as ACL information.

<pre>
rpz:
        name: <zone-name>
        zonefile: zonefiles/<zone-name>
        master: <distribution-masters>
        rpz-log: yes
        rpz-log-name: <zone-name>
</pre>

In the rpz section of the configuration file you will see a layout like the above, for each RPZ zone you will need to make a duplication of this, and insert the IPs of your masters. Multiple IPs can be added by adding additional master options.

Commercial Deteque customers will be provided with necessary masters information.  If you're using an RPZ feed from another vendor you'd add their addresses in that section.  Also note that the example template provided assumes the use of Deteque's RPZ feeds.  If using other feeds the zone names would have to be changed to match those you're pulling from your vendor.

# Update the Unbound ACLS
To prevent your RPZ enabled server from becoming an open recursive, an access list restricts who can query your server.  The default config permits only RFC-1918 addresses; you'll need to edit this ACL to include your addresses if the server is directly connected on the Internet with a public IP.  The current configuration section appears like this:

<pre>
        access-control: 0.0.0.0/0 refuse
        access-control: 127.0.0.0/8 allow_snoop
        access-control: 10.0.0.0/8 allow_snoop
        access-control: 172.16.0.0/12 allow_snoop
        access-control: 192.168.0.0/16 allow_snoop
	access-control: ::1 allow_snoop
</pre>  
 
# Starting the unbound-rpz service
If you're running a dual-stack server (a server that supports both IPv4 and IPv6) the easiest way to bring up the docker container is to use the "host" network.  This will insure that your unbound logs reflect the correct source ips.  There are several ways you can use to start the unbound server, but the easiest would be to use this script:

  <pre>
  docker run \
    --rm \
    --detach \
    --name unbound-rpz \
    --volume /etc/unbound:/etc/unbound \
    --network host \
    deteque/unbound-rpz
  </pre>

  Note that /etc/unbound is a bind mount that will "point" at the /etc/unbound directory on your physical server.

# Setting up TLS

To set up TLS you first have to have Certbot installed and an already operational certificates.

You must uncomment these lines in the unbound.conf file and edit them where relevant, particularly the <server-name>:

<pre>
        #tls-service-key: "/etc/letsencrypt/live/<server-name>/privkey.pem"
        #tls-service-pem: "/etc/letsencrypt/live/<server-name>/fullchain.pem"
        #tls-port: 853

        #tls-ciphers: "DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256"

        #tls-ciphersuites: "TLS_AES_128_GCM_SHA256:TLS_AES_128_CCM_8_SHA256:TLS_AES_128_CCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256"


        #tls-cert-bundle: "/etc/ssl/certs/ca-certificates.crt"
</pre>

The configuration is set for Let's Encrypt, but other certificates providers can be used and the configuration altered to point to the correct certificates.

The unbound-rpz instance then has to be run with a bind mount to the certificates, assuming you have Let's Encrypt add this to the docker start script:
<pre>
	--volume /etc/letsencrypt:/etc/letsencrypt
</pre>
