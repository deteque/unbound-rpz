# unbound
Unbound Recursive DNS Server configured to support response policy zones (RPZ) and DNS over TLS (DoT)

# Installation Overview
Beginning with version 1.10.0 unbound provides limited RPZ support. Currently unbound does not support the NSIP and NSDNAME RPZ triggers.

The steps to setup this docker image is as follows:

1.) Create directories on the host machine
2.) Run a setup script
3.) Create the unbound configuration file
4.) Setup your RPZ zones
5.) Setup your ACLs
6.) Setup TLS (optional)
7.) Start the unbound-rpz service

# 1.) Create directories on the host machine
Create two directories on your server: "/etc/unbound" and "/etc/unbound/zonefiles".  The /etc/unbound directory will be primarily used to store log and configuration files.  The /etc/unbound/zonefiles directory will be used to store the RPZ zonefiles.  The /etc/unbound directory will be bind mounted when the container is run.  You can create both directories by:

  mkdir -p /etc/unbound/zonefiles

# 2.) Run a setup script
This setup script will need to be run:

  docker run --rm -v /etc/unbound:/etc/unbound/ deteque/unbound-rpz /root/scripts/setup-unbound.sh

This will add keys for DNSSEC, unbound-control and create the root.cache which is necessary for a recursive name server. The root.cache should be updated periodically by running:

  /usr/bin/wget --user=ftp --password=ftp ftp://ftp.rs.internic.net/domain/db.cache -O /etc/unbound/root.cache
  
# 3.) Create the unbound configuration file
The primary configuration file for unbound is unbound.conf. From within the container, a "mostly" configured unbound.conf can be found at /root/unbound/unbound.conf.  The sample file contains everything needed to get the dns server up and running except for the master IPs in the RPZ section as well as ACL information. This file is truncated to include only the relevant options. The full configuration file can be found at /root/unbound/unbound.conf.DISTRIBUTION.
These files can be copied from the docker image with this script:

	docker run --rm -v /etc/unbound:/etc/unbound/ deteque/unbound-rpz /bin/cp /root/unbound/unbound.conf /etc/unbound/zonefiles/

or:

	docker run --rm -v /etc/unbound:/etc/unbound/ deteque/unbound-rpz /bin/cp /root/unbound/unbound.conf.DISTRIBUTION /etc/unbound/zonefiles/ 

# 4.) Setup your RPZ zones
In the rpz section of the configuration file you will see a layout like the one below, for each RPZ zone you will need to make a duplication of this, and insert the IPs of your masters. Multiple IPs can be added by adding additional master options.

<pre>
	rpz:
        	name: [zone-name]
	        zonefile: zonefiles/[zone-name]
	        master: [distribution-masters]
        	rpz-log: yes
        	rpz-log-name: [zone-name]
</pre>


Commercial Deteque customers will be provided with necessary masters information.  If you're using an RPZ feed from another vendor you'd add their addresses in that section.  Also note that the example configuration template provided in the docker image assumes the use of Deteque's RPZ feeds.  If using other feeds the zone names would have to be changed to match those you're pulling from your vendor.

# 5.) Setup your ACLs
To prevent your RPZ enabled server from becoming an open recursive, an access list restricts who can query your server.  The default config permits only RFC-1918 addresses; you'll need to edit this ACL to include your addresses if the server is directly connected on the Internet with a public IP.  The current configuration section appears like this:

<pre>
        access-control: 0.0.0.0/0 refuse
        access-control: 127.0.0.0/8 allow_snoop
        access-control: 10.0.0.0/8 allow_snoop
        access-control: 172.16.0.0/12 allow_snoop
        access-control: 192.168.0.0/16 allow_snoop
	access-control: ::1 allow_snoop
</pre>  
 
# 6.) Setup TLS (optional)
Unbound provides native support for DNS over TLS (DoT).  If implemented, Unbound will open up TCP port 853 and accept encrypted queries.  If you wish to implement DoT you'll also require a proxy on the client side that will accept dns queries, encrypt them then forward them to your DoT enabled Unbound server.  One popular dns proxy that supports DoT is called stubby.  We publish a stubby Docker image that should be ideal for testing out DoT; you can pull it from Docker Hub at deteque/stubby.

In order to implement DoT in Unbound you'll first need to obtain TLS certificates.  We recommend using bona fide certs rather than self-signed certs.  The easiest way to obtain legitimate certs is to use LetsEncrypt.

In order to install certificates from LetsEncrypt you will have to install "certbot". To install certbot port 80 must be open, not firewalled off, and not in use by another service. Running the following commands will install certbot and create certificates, replace [DOMAIN-NAME] with the fully qualified domain name of the server, excluding the brackets:

<pre>

mkdir -p /web/certs
cd /web/certs
/usr/bin/wget https://dl.eff.org/certbot-auto
chmod 700 /web/certs/certbot-auto
/web/certs/certbot-auto certonly --standalone -d [DOMAIN-NAME]

</pre>

To enable DoT and TLS in the unbound service you must uncomment these lines in the unbound.conf file and edit them where relevant, particularly the [DOMAIN-NAME], which should bei replaced with the fully qualified domain name used earlier, again excluding the brackets:

<pre>
        #tls-service-key: "/etc/letsencrypt/live/[DOMAIN-NAME]/privkey.pem"
        #tls-service-pem: "/etc/letsencrypt/live/[DOMAIN-NAME]/fullchain.pem"
        #tls-port: 853

        #tls-ciphers: "DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256"

        #tls-ciphersuites: "TLS_AES_128_GCM_SHA256:TLS_AES_128_CCM_8_SHA256:TLS_AES_128_CCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256"


        #tls-cert-bundle: "/etc/ssl/certs/ca-certificates.crt"
</pre>

The configuration is setup for Let's Encrypt, but other certificate providers can be used and the configuration altered to point to the correct certificates.

# 7.) Start the unbound-rpz service
If you're running a dual-stack server (a server that supports both IPv4 and IPv6) the easiest way to bring up the docker container is to use the "host" network.  This will insure that your unbound logs reflect the correct source IPs.  There are several ways you can use to start the unbound server, but the easiest would be to use this script:

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

If you are using TLS an additional bind mount to the certificates needs to be used in the script. Assuming you are using Let's Encrypt:

<pre>
  docker run \
    --rm \
    --detach \
    --name unbound-rpz \
    --volume /etc/unbound:/etc/unbound \
    --volume /etc/letsencrypt:/etc/letsencrypt \
    --network host \
    deteque/unbound-rpz

</pre>

