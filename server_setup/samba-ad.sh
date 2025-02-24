#!/bin/bash
# SAMBA-AD SETUP
################
#Variables
REALM="SAMBA.INTERNAL";
DOMAIN="samba";
ADPWD="Admin@Passw0rd";
SOPHOS=$(ip r | awk '/default/ {print $3}');
LAN=$( ip r | awk '/link/ {print $1}');
LANREV="2.24.172";
IP=$( ip r | awk '/link/ {print $9}');

#Install 
#/usr/bin/apt-get -y update;
#/usr/bin/apt-get -y install samba-ad-dc bind9 kea-dhcp4-server krb5-kdc krb5-admin-server;

#Setup local files
echo "$IP dc.$REALM" >> /etc/hosts

#Configure
kdb5_util create -s;
rm /etc/samba/smb.conf;
samba-tool domain provision --server-role=dc --use-rfc2307 --dns-backend=BIND9_DLZ --realm=$REALM --domain=$DOMAIN --adminpass=$ADPWD;
cp /var/lib/samba/private/krb5.conf /etc/krb5.conf;

## bind config file
cat <<EOF>/etc/bind/named.conf.options
acl trusted{
	$LAN;
};
options {
        directory "/var/cache/bind";

        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

        // If your ISP provided one or more IP addresses for stable
        // nameservers, you probably want to use them as forwarders.
        // Uncomment the following block, and insert the addresses replacing
        // the all-0's placeholder.

        forwarders {
              $SOPHOS;
        };
	allow-query { trusted; };
        //========================================================================
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //========================================================================
        dnssec-validation no;
	tkey-gssapi-keytab "/usr/local/samba/private/dns.keytab";
     	minimal-responses yes;
        listen-on-v6 { none;};
};
EOF

#Configure System-DNS
echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf;

echo "nameserver $IP" > /etc/resolv.conf;
chattr +i /etc/resolv.conf;
systemctl restart named;

#Should work
# DEBUG:
# smbclient -L localhost -N
# host -t SRV _ldap._tcp.$DOMAIN

clear
cat /etc/hostname
cat /etc/hosts
