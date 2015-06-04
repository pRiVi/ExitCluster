#!/bin/bash
if [[ "$2" == "" ]]; then
   echo "You have to give an hostname and default ip!";
   exit 0;
fi
(grep -v vpn.service /etc/hosts; host $1|perl -ne '/has address ([\d\.]+)$/ && (print $1." vpn.service\n") && system("route add -host ".$1." gw '$2'")') >/etc/hosts.new; mv /etc/hosts.new /etc/hosts

