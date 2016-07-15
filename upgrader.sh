#!/usr/local/bin/zsh
### Automatic upgrade for ports (and pkg on root system)
### for root system and all defined jails

# Array of Jails
jails=(db mail proxy www ssl admin letsencrypt vpn)


## Start logging
echo "### ### Starting Upgrader at `date` ### ###"

echo "Do you want to update Ports and FreeBSD?? (y/N)"
stty raw -echo
char=`dd bs=1 count=1 2>/dev/null`
stty -raw echo
# Update Root Repository
if [ "y" = "$char" ]; then
echo "### ### Fetch FreeBSD and Port Updates ### ###"
  freebsd-update fetch
  portsnap fetch update
  svn update /usr/src
fi

echo "### ### Checking Root-System ### ###"
pkg version -l "<"
echo "Do you want install updates on root system?? (y/N)"
stty raw -echo
char=`dd bs=1 count=1 2>/dev/null`
stty -raw echo
# Update Root Repository
if [ "$char" = "y" ]; then
  freebsd-update install
  portupgrade -a
  csh -t rehash
  # delete outdated ports data
  find /var/ports/usr/ports/* -maxdepth 1 -mtime +3 -exec rm -rf {} \;
  find /var/ports/distfiles/* -maxdepth 1 -mtime +30 -exec rm -rf {} \;
  pkg update
  csh -t rehash
fi

pkg version -l "<"
echo "Do you want check your packages on root system?? (y/N)"
stty raw -echo
char=`dd bs=1 count=1 2>/dev/null`
stty -raw echo
# Check Root Repository
if [ "$char" = "y" ]; then
  pkg check -dsa
fi

# Now update in all jails
for jailname in $jails
  do

  echo "### ### Checking Jail $jailname ### ###"
  jexec -n $jailname pkg version -l "<"
  echo "Do you want install updates on jail $jailname?? (y/N)"
  stty raw -echo
  char=`dd bs=1 count=1 2>/dev/null`
  stty -raw echo
  # Update Jail Repository
  if [ "$char" = "y" ]; then
    #jexec -n $jailname pkg update // packages will be compiled from ports tree
    jexec -n $jailname portupgrade -a
    jexec -n $jailname csh -t rehash
    if [ "$jailname" = "ssl" ]; then
      echo "### ### Reset Dirs in $jailname back to used defaults ### ###"
      jexec -n $jailname chown -R cloud.werzel.de:www /usr/local/www/owncloud
      jexec -n $jailname chown -R mail.werzel.de:www /usr/local/www/roundcube
      jexec -n $jailname chown -R squirrel.werzel:www /usr/local/www/squirrelmail
    fi
    # delete outdated ports data
    jexec -n $jailname find /var/ports/usr/ports/* -maxdepth 1 -mtime +3 -exec rm -rf {} \;
    jexec -n $jailname find /var/ports/distfiles/* -maxdepth 2 -mtime +30 -exec rm -rf {} \;
  fi

  pkg version -l "<"
  echo "Do you want check your packages on jail $jailname?? (y/N)"
  stty raw -echo
  char=`dd bs=1 count=1 2>/dev/null`
  stty -raw echo
  # Check Jail Repository
  if [ "$char" = "y" ]; then
    pkg check -dsa
  fi

done

echo "### ### Finished Upgrader at `date` ### ###"