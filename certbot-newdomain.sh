#!/usr/local/bin/zsh
### This helper script will stop firewall for port 443 and redirect this to letsencrypt jails
### Now letsencrypt can either dump "dry-run" data or renew certificate with new domain

logfile=/var/log/letsencrypt.log
#letsencrypt dryrun
dryrun=0

#Remove Logfile prior to use.
rm -f  $logfile

exec > $logfile
exec 2>&1
echo "Starting Letsencrypt for new domains at `date`"

## Redirect Port 443 to Jail Letsencrypt
echo "Start Firewall with 443 to letsencrypt"
pfctl -f /etc/pf-letsencrypt.conf

# Generate new certificates (up to 100 domains / subdomains per request, only 5 requests per week!)
echo "Start Letsencrypt in Renewal Mode"
# Mail and mail related
#jexec -n letsencrypt certbot certonly --duplicate --renew-by-default -c /etc/letsencrypt/cli.ini -d mail.werzel.de -d webmail.werzel.de -d squirrel.werzel.de -d automx.werzel.de -d autoconfig.werzel.de -d autodiscover.werzel.de
if [ "1" =  "1" ]; then
  # Normally start dry run to write log with domain info from cert
  # RENEWAL ONLY!
  jexec -n letsencrypt certbot renew --dry-run
  jexec -n letsencrypt cat /var/log/letsencrypt/letsencrypt.log
else
  ### This will only be started with additional parameter: Add additional domain names to the list from cert.
  ### Enter domain list manually here
  jexec -n letsencrypt certbot renew --expand -d xxx
fi

## Redirect Port 443 back to Jail Proxy
echo "Start Firewall with normal configuration"
pfctl -f /etc/pf.conf

# Send mail with results
echo "Ending Letsencrypt for new domains at `date`, sending mail with results"
mail -s "Result of new Letsencrypt domains" root@mail.werzel.de <$logfile
