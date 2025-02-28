#!/bin/bash
apt update
apt install wget apache2 apparmor-profiles mysql-server php libapache2-mod-php php-mysql
echo "FIREWALL"
ufw allow 443 
ufw allow 80
ufw allow 22
ufw enable

# MYSQL
echo "MYSQL"
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';" | mysql
mysql_secure_installation
echo "CREATE USER 'ncdbuser'@'localhost' IDENTIFIED BY 'password';" | mysql
echo "CREATE DATABASE ncdb" | mysql
echo "GRANT ALL PRIVILEGES ON ncdb.* TO 'ncdbuser'@'localhost';" | mysql

# NC Install
echo "Installing NC"
mkdir /var/www/nextcloud
cd /var/www/nextcloud
chown www-data:www-data /var/www/nextcloud
wget https://download.nextcloud.com/server/installer/setup-nextcloud.php

cat > /etc/apache2/sites-enabled/nc-install.conf<<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/nextcloud
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

cat > /etc/apache2/sites-available/nextcloud.conf<<EOF
<VirtualHost *:80>
    ServerName nc.lan
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/nextcloud
	  <Directory /var/www/html/nextcloud/>
	    Require all granted
	    AllowOverride All
	    Options FollowSymLinks MultiViews

	    <IfModule mod_dav.c>
	      Dav off
	    </IfModule>
	  </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error_nc.log
    CustomLog \${APACHE_LOG_DIR}/access_nc.log combined
</VirtualHost>
EOF
a2dissite 000-default.conf
echo "Pleas go to the webpage localhost:80/setup-nextcloud.php and finish the Setup"
echo Finished?
read
#NC config
apt install php-zip php-xml php-gd php-curl php-mbstring php-imagick php-apcu
apache2ctl restart
sed -i 's/output_buffering.*/output_buffering = Off/' /etc/php/*/apache2/php.ini
sed -i 's/memory_limit.*/memory_limit = 1024M/' /etc/php/*/apache2/php.ini
sed -i 's/opcache.interned_strings_buffer.*/opcache.interned_strings_buffer=16/' /etc/php/*/apache2/php.ini
CONFIGNC=$(head -n -1 /var/www/nextcloud/config/config.php)
cat > /var/www/nextcloud/config/config.php << EOF
$CONFIGNC
'skeletondirectory'=>'',
'maintenance_window_start' => 1,
'memcache.local' => '\OC\Memcache\APCu',
);
EOF
sudo -u www-data php -f /var/www/nextcloud/occ maintenance:repair --include-expensive

# SSL
apt install snapd
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
snap set certbot trust-plugin-with-root=ok
snap install certbot-dns-cloudflare
certbot

a2ensite nextcloud.conf
apache2ctl restart

# FAIL2BAN
echo "Fail2ban"
apt install fail2ban
cat >> /etc/fail2ban/filter.d/nextcloud.conf << EOF
[Definition]
_groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
            ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Two-factor challenge failed:
            ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
EOF

cat >> /etc/fail2ban/jail.d/nextcloud.local << EOF
[nextcloud]
backend = auto
enabled = true
port = 80,443
protocol = tcp
filter = nextcloud
maxretry = 3
bantime = 86400
findtime = 43200
logpath = /var/log/apache2/access_nc.log
EOF

echo "STATUS"
echo "LET ENCRYPT"
echo "NC VHOST FILE"
aa-status
apache2ctl -S
fail2ban-client status nextcloud
echo "visit https://docs.nextcloud.com/server/30/admin_manual/installation/server_tuning.html for more"
