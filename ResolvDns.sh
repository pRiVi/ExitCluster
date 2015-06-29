#!/bin/sh
if [[ "$1" == "" ]]; then
   echo "ERROR: You have to give a hostname!";
   echo "Syntax: $0 HOSTNAME [DNS] [GATEWAY] [FAKEHOSTNAME]";
   exit 1;
else 
   export HOST=$1;
fi

if [[ "`uname -a|grep mips`" == "" ]]; then
   export NOOPENWRT=1
else
   echo Determined OpenWRT;
fi

export CURGW=`route -n|sed -e 's/0.0.0.0 \{1,\}\([0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}\) \{1,\}0.0.0.0.*/\1/p' -e 'd'`

if [[ "$3" == "" ]]; then
   /bin/true;
else
   export GW=$3
fi

if [[ "$GW" == "" ]]; then
   export GW=`cat /tmp/cur.gw`
fi

if [[ "$GW" == "" ]]; then
   export GW=$CURGW
   echo $GW >/tmp/cur.gw
fi

if [[ "$2" == "" ]]; then
   export DNS=8.8.8.8
else
   export DNS=$2
fi

if [[ "$4" == "" ]]; then
   export FAKEHOSTNAME=vpn.service
else
   export FAKEHOSTNAME=$4
fi

if ! `test -f /tmp/firstrun`; then
   if [[ "$NOOPENWRT" == "" ]]; then
      /usr/sbin/ntpd -p $FAKEHOSTNAME
   fi
   touch /tmp/firstrun;
fi

if [[ "`grep $FAKEHOSTNAME /root/.ssh/known_hosts`"  == "" ]]; then
   cat /root/.ssh/known_hosts|grep -v $FAKEHOSTNAME >/root/.ssh/known_hosts.new;
   echo $FAKEHOSTNAME ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBcI28PxOM38w+8La4uYW1/oYG+uYDUPnLU4zBFSrzRC0laW0tE7KVzbzF7/3rCbwfrDG/Kz5ivxKdyrI64oms3P8TUYBbWrtZnSVRCjn8fpFKTD8f3W/C9K39jhp2ubRMFuLbcyS9XhnH9uLKMEgUakRs9DgndibXmN0ee3tIO1Qr+4qdw+4X399uXRalmlfEEjT7qSIg9oIIzJoX5QrI74jJXv61rNrgH/rZmwGwAVLP2oqevexh9vh4jmAZlUT6eb/RwXKRYtK4odcli1She9P2zTdszeVfvvhnwN2HmNDHvSyr7zvFstws2RpjUPCC5Y6VVT/5QSIx3RCd16yZ >>/root/.ssh/known_hosts.new;
   mv /root/.ssh/known_hosts.new /root/.ssh/known_hosts
fi

if [[ "$GW" == "" ]]; then
   echo "Could not determine your gateway!"
   exit 2;
else
   if [[ "$NOOPENWRT" == "" ]]; then
      echo "GW=$GW DNS=$DNS HOST=$HOST";
      route add -host $DNS gw $GW;
      for i in 0.openwrt.pool.ntp.org 1.openwrt.pool.ntp.org 2.openwrt.pool.ntp.org 3.openwrt.pool.ntp.org; do
         for j in `nslookup $i $DNS|sed -e "/$DNS/d" -e 's/Address.*[0-9]\{0,\}: \{0,\}\([0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}\).*/\1/p' -e 'd' | tr "" "\n"`; do
            echo route add -host $j gw $GW;
            route add -host $j gw $GW;
         done
      done
   fi
fi
export DSTIP=`nslookup $HOST $DNS|sed -e "/$DNS/d" -e 's/Address.*[0-9]\{0,\}: \{0,\}\([0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}\).*/\1/p' -e 'd'`
if [[ "$DSTIP" == "" ]]; then 
   echo Could not determine dst ip!;
else 
   echo Got IP $DSTIP
   /bin/grep -v $FAKEHOSTNAME /etc/hosts >/etc/hosts.new;
   echo $DSTIP $FAKEHOSTNAME >>/etc/hosts.new;
   /bin/mv /etc/hosts.new /etc/hosts;
   /sbin/route add -host $DSTIP gw $GW
   if [[ "$CURGW" == "$GW" ]]; then
      /sbin/route delete default
   fi
   if [[ "$NOOPENWRT" == "" ]]; then
      if ! `test -f /usr/sbin/openvpn`; then
         cd /tmp;
         for i in `/usr/bin/ssh -T -i /etc/openvpnkey dynloader@$FAKEHOSTNAME |/bin/tar -xzvf -`; do
            if ! `test -d /$i`; then /bin/ln -s /tmp/$i /$i; fi;
         done;
      fi
      modprobe tun
   fi
   cd /etc/openvpn
   /usr/sbin/openvpn --config /etc/openvpn/vpn.priv.de.conf &
fi

