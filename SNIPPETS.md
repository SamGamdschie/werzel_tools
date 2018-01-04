# Werzel Tools
Tools and Snippets for my FreeBSD administration

## Snippets
 #! /bin/nosh
freebsd-update fetch
freebsd-update install
freebsd-update rollback

### Portsnap
portsnap fetch update
pkg2ng
portupgrade -a
portupgrade -rfa

### Port-Managment
portupgrade -ran
env DISABLE_CONFLICTS=1
portupgrade -o lang/perl5.24 -f perl5.14
portupgrade -fr perl
portupgrade -o databases/postgresql95-client -f postgresql90-client
portupgrade -o databases/mariadb101-client -f mariadb100-client
portupgrade -fr mariadb101-client
portupgrade -o databases/mariadb101-server -f mariadb100-server
portupgrade -o lang/ruby23 -f ruby
portupgrade -fr ruby
portupgrade -o security/openssl -f libressl

## Via portmaster if PHP
#change versions and origin accordingly!
portmaster -o lang/php71 php56-5.6.30
pkg info | grep php | grep 5.6 | awk '{print $1}' | awk -F '-5.6' '{print "whereis "$1}' | sh | awk -F ': /usr/ports/' '{print "portmaster -y -D -o "$2" "$1}' | sed -e "s@/php56-@/php71-@" -e 's@$@-5.6.30@' | sh
portmaster -d -y pecl

## FreeBSD Upgrade
###First upgrade all software on host
freebsd-update fetch
freebsd-update install
portsnap fetch update
portupgrade -a
###Install new version on Host
/usr/sbin/freebsd-update upgrade -r 11.1-RELEASE
/usr/sbin/freebsd-update install
/sbin/shutdown -r now
/usr/sbin/freebsd-update install
less /usr/src/UPDATING
pkg-static install -f pkg
portsnap fetch update
portupgrade -rfa
/usr/sbin/freebsd-update install
/sbin/shutdown -r now
####Now on the current release on host! some later tasks
/usr/sbin/freebsd-update fetch
/usr/sbin/freebsd-update install
pwd_mkdb -p /etc/master.passwd
mergemaster -p
less /root/.vim/.openzsh
zpool upgrade <pool>
zfs upgrade -r <pool>
/sbin/shutdown -r now
####Now upgrade Jails
ezjail-admin install
rm -rf /usr/src/* /usr/src/.*
svn checkout https://svn.freebsd.org/base/releng/11.1/ /usr/src
svn update /usr/src
mergemaster -p -D /usr/jails/db
mergemaster -p -D /usr/jails/mail
mergemaster -p -D /usr/jails/...
ezjail-admin onestart
jexec -n ### su
pkg-static install -f pkg
portupgrade -rfa (in all jails)
/sbin/shutdown -r now
less /root/.vim/.openzsh
####Optional clean up
pkg audit
pkg autoremove
portsclean -CDLP

###ZFS
zfs list -t all -o name,used,refer,written -r zroot
zfs list -ro space |less
zfs destroy -rv zroot@%
zpool status
zpool scrub <pool>
gpart bootcode -b /boot/pmbr -b /boot/gptzfsboot -i 1 ada0

##HUKL
https://github.com/hukl/freebsd-toolbox/blob/master/commands.md

##SOURCE##
svn checkout http://svn.freebsd.org/base/releng/10.1/ /usr/src
svn update /usr/src

### ezjail
ezjail-admin
ezjail-admin list
ezjail-admin onestart
ezjail-admin onerestart
ezjail-admin console
ezjail-admin delete -w
ezjail-admin create host 10.0.10.255
cp /etc/fstab.mail /etc/fstab.host
cd /usr/local/etc/ezjail/
vi ** #change jail parameters: add int.werzel.de to hostname
cp /usr/jails/ssl/etc/hosts /usr/jails/newjail/etc/hosts
vi /usr/jails/newjail/etc/hosts
cp /usr/jails/ssl/etc/resolv.conf /usr/jails/newjail/etc/resolv.conf
cp /usr/jails/ssl/etc/localtime /usr/jails/newjail/etc/localtime
rm /usr/jails/newjail/usr/ports
mkdir -p /usr/jails/newjail/usr/ports

##Sendmail als Mailqueue (for non-mail jails)
cd /etc/mail
make
vi $hostname.submit.mc
:%s/\[127.0.0.1\]/\[10.0.10.1\]/g
make install
vi /etc/rc.conf
sendmail_enable="NO"
sendmail_msp_queue_enable="YES"
sendmail_outbound_enable="NO"
sendmail_submit_enable="YES"
cd /etc/mail && make stop && make start

## Firewall
tcpdump -n -e -ttt -i pflog0
 #! /bin/sh

### Passwordschutz
perl -le 'print crypt ("password", "salt")'
echo "user:passwordhash:comment"

### User Management
pw user add example.com -s /sbin/nologin
pw group mod example.com -m www

### Directories and Permissions
mkdir /www/vhosts/example.com
cd /www/vhosts/example.com
mkdir log sessions tmp htdocs
chown -R example.com:example.com /www/vhosts/example.com
chown -R www:example.com .log
chmod -R 770 log
chmod -R 770 tmp
chmod -R 700 sessions
chmod -R 750 htdocs

find . -type d -exec chmod 550 {} \;
find . -type f -exec chmod 440 {} \;

### Wordpress ###
https://wordpress.org/plugins/better-wp-security/

### Nginx Cache
find /tmp/nginx/cache -type f -delete

### Let's Encrypt Feature and Settings
/etc/letsencrypt/live/$domain
/etc/letsencrypt/archive
/etc/letsencrypt/keys
privkey.pem = ssl_certificate_key
fullchain.pem =  ssl_certificate
rsa-key-size = 4096
email = foo@example.com
authenticator = standalone
standalone-supported-challenges = http-01
 -d thing.com -d www.thing.com -d otherthing.net

### pf
pfctl -f pf-letsencrypt.conf
pfctl -f pf.conf
pfctl -t werzelhome -T show
pfctl -t werzelhome -T flush
pfctl -t bruteforce -T delete 1.1.1.1

openssl x509 -text -noout -in

ssh-keygen -t ed25519 -o -a 100
ssh-keygen -t rsa -b 4096 -o -a 100
#Keyagent under MacOS
ssh-add -K key_name
ssh-add -l

## NEW SECURE SECURE SHELL
Protocol 2
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
Port 2345
ListenAddress 217.79.181.55
PermitRootLogin no
AllowGroups wheel
Subsystem  sftp  /usr/libexec/sftp-server
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
PasswordAuthentication yes
ChallengeResponseAuthentication no
PubkeyAuthentication yes
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-ripemd160-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,umac-128@openssh.com

https://stribika.github.io/2015/01/04/secure-secure-shell.html

http://ohmyz.sh/community/
https://tmuxcheatsheet.com/

## macOS ##
<CMD> + <Shift> + <.>

defaults write com.apple.finder AppleShowAllFiles True
killall Finder
