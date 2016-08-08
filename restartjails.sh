#!/usr/local/bin/zsh

# Array of Jails
jails=(db mail proxy www ssl admin letsencrypt vpn bitcoin)
phpjails=(www ssl admin)
## Remove Log & start logging
echo "Starting Jailrestart  at `date`"

echo "Stopping all Jails now:"
# Now update in all jails
for jailname in $jails
  do
  ezjail-admin onestop $jailname
done

echo "All jails are stopped now."
echo ""
echo "Starting Jails again in same order:"
for jailname in $jails
  do
  ezjail-admin onestart $jailname
done

for jailname in $phpjails
  do
  echo "Retarting PHP in Jail $jailname"
  jexec -n $jailname  service php-fpm stop
  jexec -n $jailname  service php-fpm start
done
