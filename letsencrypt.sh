#!/usr/local/bin/zsh
logfile=/var/log/letsencrypt.log
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
echo "Starting Letsencrypt via ACME.SH at `date`"

# Generate new certificates (up to 100 domains / subdomains per request, only 5 requests per week!)
echo "Start Letsencrypt in Renewal Mode"
# RENEWAL ONLY!
if [ "1" = "$dryrun" ]; then
  #jexec -n letsencrypt certbot renew -n --dry-run
  jexec -n letsencrypt acme.sh --home /var/db/acme/.acme.sh/ --cron --test
else
  #jexec -n letsencrypt certbot renew -n --rsa-key-size 4096
  jexec -n letsencrypt acme.sh --home /var/db/acme/.acme.sh/ --cron --always-force-new-domain-key
fi
#

# check that certificates were regenerated
# only in this case also regenerate DH parameters
sucess=`grep "Cert success." $logfile | grep -Eo "success" | head -1`
if [ "$sucess" = "success" ]; then
## Regenerate DH Parameters
  echo "Regenerate DH Parameters including smaller ones for postfix"
  openssl dhparam -out /werzel/certificates/werzel.de.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/k5sch3l.werzel.de.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/mail.werzel.de.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/mail.werzel.de.512.pem 512
  openssl dhparam -out /werzel/certificates/mail.werzel.de.1024.pem 1024
  openssl dhparam -out /werzel/certificates/mail.werzel.de.2048.pem 2048
  openssl dhparam -out /werzel/certificates/hobbingen.de.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/seeadler.org.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/bist.gmbh.dhparam.pem 4096
  openssl dhparam -out /werzel/certificates/knappemail.de.dhparam.pem 4096

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

## openssl x509 -text -noout -in cert.pem | grep DNS
## acme.sh --home /var/db/acme/.acme.sh/ --keylength 4096 --dns dns_inwx --issue -d
## acme.sh --home /var/db/acme/.acme.sh/ --cron > /dev/null
## acme.sh --home /var/db/acme/.acme.sh/ --remove -d
## --keylength ec-256|ec-384
## -d *.example.com
## --test
##
# -d k5sch3l.werzel.de
# -d werzel.de -d *.werzel.de
# -d mail.werzel.de -d webmail.werzel.de -d squirrel.werzel.de -d autoconfig.werzel.de -d autodiscover.werzel.de -d automx.werzel.de -d lists.chemiker-hh.de -d lists.hobbingen.de -d lists.werzel.de
# -d hobbingen.de -d *.hobbingen.de
# -d seeadler.org -d *.seeadler.org
# -d knappemail.de -d *.knappemail.de
# -d bist.gmbh -d bist-gmbh.de -d *.bist.gmbh -d *.bist-gmbh.de -d bist.werzel.de
