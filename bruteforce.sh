#!/usr/local/bin/zsh
# Array of Jails
hosts=()

# Now update on all hosts
for host in $hosts
  do
  /sbin/pfctl -t bruteforce -T add $host
done

