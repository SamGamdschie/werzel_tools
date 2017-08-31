#!/usr/local/bin/zsh
# Array of Jails
jails=(db mail proxy www ssl admin letsencrypt vpn)
logfile=/var/log/portcheck.log
tmplog=/var/log/portcheck.tmp.log
#emailaddr=root@mail.werzel.de
emailaddr=server.mail@werzel.de
fetchtdata=1

## Start logging
rm -rf $logfile
exec > $tmplog
exec 2>&1
echo "### ### Starting Portcheck at `date` ### ###"

if [ "$fetchdata" = "1" ]; then
# Update Root Repository
  echo "### ### Fetch FreeBSD and Source Updates ### ###"
  freebsd-update -t root@mail.werzel.de cron
  svn update /usr/src >/dev/null
fi

echo "### ### Fetch Port Updates ### ###"
/usr/sbin/portsnap cron
/usr/sbin/portsnap -I update

echo "### ### Checking Root-System ### ###"
pkg audit
pkg version -l "<"
pkg check -dsa

# Now update in all jails
for jailname in $jails
  do

  echo "### ### Checking Jail $jailname ### ###"
  jexec -n $jailname pkg audit
  jexec -n $jailname pkg version -l "<"
  jexec -n $jailname pkg check -dsa

done

echo "### ### Now checking system status using LYNIS ### ###"
lynis audit system >/dev/null
cat /var/log/lynis.log

echo "### ### Stopping Portcheck at `date`, sending mail with results ### ###"
grep -v "Upgrad" $tmplog | grep -v "^OK? \[no\]" | grep -v "^\[Reading data from pkg" | grep -v "packages found \- done" >$logfile
mail -s "Result of Automatic Updates" $emailaddr <$logfile
#Log sent, renove it.
rm -f $tmplog
