#!/usr/local/bin/zsh
#
# MAILGUARD
#
# This script checks if any entries in postfix log without DNS are comming to often
# If those IPs are in Bruteforce-Table already, they are ignored.
#
logfile=/var/log/mailguard.log
tmplog=/var/log/mailguard.tmp.log
tmpipadd=/var/log/mailguard.ip.log

rm -f  $logfile

grep "postfix\/smtpd.*disconnect .*" /usr/jails/mail/var/log/maillog | grep "unknown" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >$tmpipadd
curhour=`date "+%H"`
pftable=`/sbin/pfctl -t bruteforce -T show | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'`
echo "Starting Mailguard at `date`, sending mail with results" >$tmplog

for ipaddr in $(sort -u $tmpipadd);
  do
    intable="false";
    for brute in $pftable;
      do
        if [ "$brute" = "$ipaddr" ]; then
          intable="true";
          echo "$ipaddr is in Bruteforce-Table already" >>$tmplog
        fi
      done
    if [ "$intable" = "false" ]; then
      countip=`grep -c "$ipaddr" $tmpipadd`
      if [ "$curhour" -gt "12" ]; then
        if [ "$countip" -gt "11" ]; then
          echo "Adding $ipaddr to Bruteforce after $countip connections at `date`" >>$tmplog
          /sbin/pfctl -t bruteforce -T add $ipaddr
        fi
      elif [ "$curhour" -gt "6" ]; then
        if [ "$countip" -gt "7" ]; then
          echo "Adding $ipaddr to Bruteforce after $countip connections at `date`" >>$tmplog
          /sbin/pfctl -t bruteforce -T add $ipaddr
        fi
      else
        if [ "$countip" -gt "3" ]; then
          echo "Adding $ipaddr to Bruteforce after $countip connections at `date`" >>$tmplog
          /sbin/pfctl -t bruteforce -T add $ipaddr
        fi
      fi
    fi
  done

rm -f  $tmpipadd

# Send mail with results
cat $tmplog > $logfile
#bruteadd=`grep -Ec 'Adding [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' $tmplog`
#if [ "$bruteadd" -ge "5" ]; then
#  if [ "$bruteadd" -le "5" ]; then
#    mail -s "Added IP to Bruteforce!" root@mail.werzel.de <$logfile
#  fi
#fi
#Log sent, remove it.
rm -f  $tmplog
