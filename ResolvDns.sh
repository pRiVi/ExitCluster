#!/bin/sh
if [[ "$1" == "" ]]; then
   echo "ERROR: You have to give an hostname!";
   echo "Syntax: $0 HOSTNAME [GATEWAY] [DNS] [FAKEHOSTNAME]";
   exit 1;
else 
   export HOST=$1;
fi
if [[ "$2" == "" ]]; then
   export GW=`route -n|sed -e 's/0.0.0.0 \{1,\}\([0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}\) \{1,\}0.0.0.0.*/\1/p' -e 'd'`
else
   export GW=$2
fi
if [[ "$GW" == "" ]]; then
   export GW=`cat /tmp/cur.gw`
else
   echo $GW >/tmp/cur.gw
fi

if [[ "$3" == "" ]]; then
   export DNS=8.8.8.8
else
   export DNS=$3
fi
if [[ "$4" == "" ]]; then
   export FAKEHOSTNAME=vpn.service
else
   export FAKEHOSTNAME=$3
fi

if [[ "$GW" == "" ]]; then
   echo "Could not determine your gateway!"
   exit 2;
else
   echo "GW=$GW DNS=$DNS HOST=$HOST";
   echo route add -host $DNS gw $GW;
   route add -host $DNS gw $GW;
fi
export DSTIP=`nslookup $HOST $DNS|sed -e "/$DNS/d" -e 's/Address.*[0-9]\{0,\}: \{0,\}\([0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}\).*/\1/p' -e 'd'`
if [[ "$DSTIP" == "" ]]; then 
   echo Could not determine dst ip!;
else 
   echo Got IP $DSTIP
   grep -v $FAKEHOSTNAME /etc/hosts >/etc/hosts.new;
   echo $DSTIP $FAKEHOSTNAME >>/etc/hosts.new;
   mv /etc/hosts.new /etc/hosts;
   route add -host $DSTIP gw $GW
   route delete default
fi

