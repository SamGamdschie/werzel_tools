#!/usr/local/bin/zsh
logfile=/var/log/letsencrypt.log
#emailaddr=root@mail.werzel.de
emailaddr=server.mail@werzel.de

#letsencrypt dryrun
dryrun=0
if [ "$1" = "dryrun" ]; then
  dryrun=1
fi

#Remove Logfile prior to use.
rm -f  $logfile

exec > $logfile
exec 2>&1
echo "Starting Letsencrypt at `date`"

## Redirect Port 443 to Jail Letsencrypt
echo "Start Firewall with 443 to letsencrypt"
pfctl -f /etc/pf-letsencrypt.conf

# Generate new certificates (up to 100 domains / subdomains per request, only 5 requests per week!)
echo "Start Letsencrypt in Renewal Mode"
# Mail and mail related
#jexec -n letsencrypt letsencrypt certonly --duplicate --renew-by-default -c /etc/letsencrypt/cli.ini -d mail.werzel.de -d webmail.werzel.de -d squirrel.werzel.de -d automx.werzel.de -d autoconfig.werzel.de -d autodiscover.werzel.de
# RENEWAL ONLY!
if [ "1" = "$dryrun" ]; then
  jexec -n letsencrypt certbot renew -n --dry-run
else
  jexec -n letsencrypt certbot renew -n --rsa-key-size 4096
fi

## Redirect Port 443 back to Jail Proxy
echo "Start Firewall with normal configuration"
pfctl -f /etc/pf.conf

# check that certificates were regenerated
# only in this case also regenerate DH parameters
sucess=`grep "/usr/local/etc/letsencrypt/live" $logfile | grep -Eo "success" | head -1`
if [ "$sucess" = "success" ]; then
## Regenerate DH Parameters
  echo "Regenerate DH Parameters including smaller ones for postfix"
  openssl dhparam -out /werzel/certificates/www.werzel.de.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/cloud.werzel.de.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/k5sch3l.werzel.de.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/mail.werzel.de.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/mail.werzel.de.512.pem 512
  openssl dhparam -out /werzel/certificates/mail.werzel.de.1024.pem 1024
  openssl dhparam -out /werzel/certificates/mail.werzel.de.2048.pem 2048
  openssl dhparam -out /werzel/certificates/lists.seeadler.org.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/www.hobbingen.de.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/www.seeadler.org.dhparam.pem 4096

  ## Stop Proxy and remove cache
  echo "Stop Proxy, delete cache"
  jexec -n proxy service nginx stop
  jexec -n proxy find /tmp/nginx/cache -type f -delete

  ## Start Nginx on Proxy
  echo "Start Proxy again"
  jexec -n proxy service nginx start

  ## Reload Nginx on WWW, SSL & Admin
  echo "Restart Webservers excl. Proxy"
  jexec -n www service nginx reload
  jexec -n ssl service nginx reload
  jexec -n admin service nginx reload


  ## ReStart Mailservices (Postfix & Dovecot)
  echo "Restart Mail"
  jexec -n mail service postfix restart
  jexec -n mail service dovecot restart

fi

# Send mail with results
echo "Ending Letsencrypt at `date`, sending mail with results"
mail -s "Result of Letsencrypt" $emailaddr <$logfile
