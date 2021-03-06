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

# Generate new certificates (up to 100 domains / subdomains per request, only 5 requests per week!)
# Mail and mail related
#jexec -n letsencrypt certbot certonly  --duplicate --renew-by-default -c /etc/letsencrypt/cli.ini -d mail.werzel.de -d webmail.werzel.de -d squirrel.werzel.de -d automx.werzel.de -d autoconfig.werzel.de -d autodiscover.werzel.de
if [ $dryrun =  1 ]; then
  # Normally start dry run to write log with domain info from cert
  # RENEWAL ONLY!
  echo "Start Newdomain in Dry Run"
  jexec -n letsencrypt certbot renew -n --dry-run
  echo ""
  echo ""
  echo "Please review domains from letsencrypt logfile:"
  echo "less /usr/jails/letsencrypt/var/log/letsencrypt/letsencrypt.log"
  echo ""
  echo "Restart certbot_nowdomain.sh with commas sperataed list of domains:"
  echo "./certbot_newdomain.sh newcert example.com,example2.com,example3.com"
  echo ""
else
  ## Redirect Port 443 to Jail Letsencrypt
  echo "Please run the commands manually!"
  echo "Start Firewall with 443 to letsencrypt"
  echo "pfctl -f /etc/pf-letsencrypt.conf"

  ### This will only be started with additional parameter: Add additional domain names to the list from cert.
  ### Enter domain list manually here
  echo "Start Letsencrypt to Extend Domain"
  echo "jexec -n letsencrypt certbot certonly -n --standalone --preferred-challenges http --rsa-key-size 4096 --expand -d $2"

  ## Redirect Port 443 back to Jail Proxy
  echo "Start Firewall with normal configuration"
  echo "pfctl -f /etc/pf.conf"
  echo "Do NOT forget the last one! and heck results"
fi

# Send mail with results
echo "Ending Newdomains at `date`"
