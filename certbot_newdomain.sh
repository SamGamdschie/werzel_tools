#!/usr/local/bin/zsh
### This helper script will stop firewall for port 443 and redirect this to letsencrypt jails
### Now letsencrypt can either dump "dry-run" data or renew certificate with new domain
#letsencrypt dryrun
dryrun=1

if [ "$1" = "newcert" ]; then
   dryrun=0
   if [ "$2" = "" ]; then
      dryrun=1
   fi
fi

## Redirect Port 443 to Jail Letsencrypt
echo "Start Firewall with 443 to letsencrypt"
pfctl -f /etc/pf-letsencrypt.conf

# Generate new certificates (up to 100 domains / subdomains per request, only 5 requests per week!)
# Mail and mail related
#jexec -n letsencrypt certbot certonly --duplicate --renew-by-default -c /etc/letsencrypt/cli.ini -d mail.werzel.de -d webmail.werzel.de -d squirrel.werzel.de -d automx.werzel.de -d autoconfig.werzel.de -d autodiscover.werzel.de
if [ $dryrun =  1 ]; then
  # Normally start dry run to write log with domain info from cert
  # RENEWAL ONLY!
  echo "Start Letsencrypt as Dry Run"
  jexec -n letsencrypt certbot renew --dry-run
  echo "Please review domains from letsencrypt logfile:"
  echo "less /usr/jails/letsencrypt/var/log/letsencrypt/letsencrypt.log"
else
  ### This will only be started with additional parameter: Add additional domain names to the list from cert.
  ### Enter domain list manually here
  echo "Start Letsencrypt to Extend Domain"
  jexec -n letsencrypt certbot certonly --expand -d $2
fi

## Redirect Port 443 back to Jail Proxy
echo "Start Firewall with normal configuration"
pfctl -f /etc/pf.conf

# Send mail with results
echo "Ending Letsencrypt for new domains at `date`, sending mail with results"
