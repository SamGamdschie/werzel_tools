#!/usr/local/bin/zsh
logfile=/var/log/logchk.log
emailaddr=root@mail.werzel.de

exec > $logfile
exec 2>&1
echo "Starting Logchecker at `date`, sending mail with results"
echo "#### NGINX PROXY #### ACCESS ###"
grep " [3-5]0[0-9][0-9] " /usr/jails/proxy/var/log/nginx-access.log | grep -v "thorsten\.werner" | grep -v "maraike\.tonzel"
echo "#### NGINX PROXY #### ERROR ###"
grep " [error] " /usr/jails/proxy/var/log/nginx-error.log
echo "#### NGINX LISTS ####"
grep " 4[0-9][0-9] " /usr/jails/mail/var/log/nginx-access.log
echo "#### POSTFIX ####"
grep "postfix\/smtpd.*connect .*" /usr/jails/mail/var/log/maillog | grep -v "werzel\.de" | grep -v "versanet\.de"

# Send mail with results
mail -s "Result of Logchecker" $emailaddr <$logfile
#Log sent, remove it.
rm -f  $logfile

logfile=/var/log/transmission.log

exec > $logfile
exec 2>&1
echo "Starting Transmission Checker at `date`, sending mail with results"
echo "#### POSTFIX ####"
grep "refused to talk to me" /usr/jails/mail/var/log/maillog

# Send mail with results
mail -s "Result of Transmission Checker" $emailaddr <$logfile
#Log sent, remove it.
rm -f  $logfile
