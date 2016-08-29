#!/usr/local/bin/zsh
logfile=/var/log/logchk.log
emailaddr=root@mail.werzel.de

exec > $logfile
exec 2>&1
echo "Starting Logchecker at `date`, sending mail with results"
echo "#### NGINX PROXY #### ACCESS ###"
grep " [3-5]0[0-9] " /usr/jails/proxy/var/log/nginx-access.log | grep -v "thorsten\.werner" | grep -v "maraike\.tonzel"
echo "#### NGINX PROXY #### ERROR ###"
grep " [error] " /usr/jails/proxy/var/log/nginx-error.log | grep -v "thorsten\.werner" | grep -v "maraike\.tonzel"
echo "#### NGINX CLOUD ####"
grep " 40[0-9] " /usr/jails/ssl/www/vhosts/cloud.werzel.de/.log/nginx.access.log | grep -v "thorsten\.werner" | grep -v "maraike\.tonzel"
echo "#### NGINX WEBMAIL ####"
grep " 40[0-9] " /usr/jails/ssl/www/vhosts/mail.werzel.de/.log/nginx.access.log
echo "#### NGINX LISTS ####"
grep " 40[0-9] " /usr/jails/mail/var/log/nginx-access.log
echo "#### POSTFIX ####"
grep "postfix\/smtpd.*connect .*" /usr/jails/mail/var/log/maillog | grep -v "werzel\.de" | grep -v "versanet\.de"

# Send mail with results
mail -s "Result of Logchecker" $emailaddr <$logfile
#Log sent, remove it.
rm -f  $logfile
