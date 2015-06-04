#!/bin/bash
if [[ "$1" == "" ]]; then
   echo "You have to give an hostname and default ip if you want automatic routes!";
   exit 0;
fi
if [[ "$3" == "" ]]; then
   export FAKEHOSTNAME=vpn.service
else
   export FAKEHOSTNAME=$3
fi
(grep -v $FAKEHOSTNAME /etc/hosts; host $1|perl -ne '/has address ([\d\.]+)$/ && (print $1." ".$ENV{FAKEHOSTNAME}."\n") && $2 && system("route add -host ".$1." gw '$2'")') >/etc/hosts.new; mv /etc/hosts.new /etc/hosts

