#!/usr/local/bin/zsh
### This helper script will stop firewall for port 443 and redirect this to letsencrypt jails
### Now letsencrypt can either dump "dry-run" data or renew certificate with new domain
validdomain=0

if [ "$1" = "www" ]; then
   validdomain=1
fi
if [ "$1" = "ssl" ]; then
   validdomain=1
fi
if [ "$1" = "admin" ]; then
   validdomain=1
fi
if [ "$2" = "" ]; then
   validdomain=0
fi

if [ $validdomain = 1 ]; then
  jail=$1
  user=$2
  ### User Management
  jexec -n $jail pw user add $user -s /sbin/nologin
  jexec -n $jail pw group mod $user -m www

  ### Directories and Permissions
  dir=/www/vhosts/$user
  jexec -n $jail mkdir $dir
  jexec -n $jail cd $dir && mkdir log sessions tmp htdocs
  jexec -n $jail chown -R $user:$user $dir
  jexec -n $jail chown -R www:$user $dir/log
  jexec -n $jail chmod -R 770 $dir/log
  jexec -n $jail chmod -R 770 $dir/tmp
  jexec -n $jail chmod -R 700 $dir/sessions
  jexec -n $jail chmod -R 750 $dir/htdocs

  jexec -n $jail find $dir/htdocs/ -type d -exec chmod 550 {} \;
  jexec -n $jail find $dir/htdocs/ -type f -exec chmod 440 {} \;

  echo "User created, directory created, permissions set: Set up NGINX & Proxy"

else

  # Echo results
  echo "Either Jail or Domain is not valid!"
  echo "Usage: create_domain.sh JAIL DOMAIN"

fi
