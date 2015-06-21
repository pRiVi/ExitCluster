# VPN Tunnelinstallation for Exit Cluster

Currently support for debian (x86/arm) and OpenWRT.

## Base config

Configure your system to be able to access the internet, at best via DHCP.

The following screenshots are tested to have a working firewall config:

<img src="screenshots/screenshot1.png" width="200" height="191">

<img src="screenshots/screenshot2.png" width="200" height="191">

<img src="screenshots/screenshot3.png" width="209" height="200">

<img src="screenshots/screenshot4.png" width="209" height="200">

## Install needed files

Copy ResolvDns.sh on your system to /bin/ and openvpnkey to /etc/. If you use OpenWRT you have to enable cron the following way:

```sh
$ /etc/init.d/cron enable
```

## Installation of OpenVPN

### Debian

```sh
$ apt-get install openvpn
```

You have to enable autostart in /etc/default/openvpn.

### OpenWRT

#### With Flash >= 8 MB:

```sh
$ opkg update
$ opkg install openvpn-openssl
```

#### With Flash < 8 MB:

With 4 MB Flash you do not have enough persistent space on your device to store OpenVPN on it, so you have to download it dynamically from your local LAN or Internet to your absconding RAM. All for this has been already integrated into ResolvDns.sh if you are using OpenWRT 14.07, it should by itself download OpenVPN from the VPN server dynamically if you have not installed by yourself as described above.

If you want or must created an tar.gz of your own, so see below 7a) to 7h). Otherwise you can use our build for 14.07 unchanged, it might run on different versions but this is completely untested.

## Install config

Copy your OpenVPN Config (vpn.priv.de.conf, client.crt, client.key and vpn.priv.de.crt) to /etc/openvpn/. Create the folder it it do not exists with "mkdir /etc/openvpn".

## Configure system

Add the following to your crontab, running "crontab -e". You can find YOURTOLDVPNHOSTNAME in your vpn.priv.de.conf file in the first line.

* * * * * /bin/sh /bin/ResolvDns.sh YOURTOLDVPNHOSTNAME

## Reboot & Enjoy.

# Creation of tar.gz for dynamic loading of OpenVPN ###

For creation of the OpenVPN tar.gz you need enough space on your OpenWRT to be able to create a installation you can copy. Cause you donnot have enough space on your system, you must use space from a remote system. This is possible via NFS. Cause you have not enouth space to install the NFS on your system, you have to install this via a trick to work around this.

You must be able to install a NFS server by yourself, this documentation do not cover that. Google might help you with "nfs howto".

## Extract NFS tools

You can jump to next step, if you already have copied the files mentioned.

Store the nfs userspace tool (mount.nfs) on external storage. For this you have to temporary install them, fetch them, and then free the memory again. Install NFS userspace tools via

```sh
$ opkg update
$ opkg install nfs-utils
```

Copy /sbin/mount.nfs and /lib/librpc.so (for examble via SSH) to a remote server.

```sh
# Example:
$ scp /sbin/mount.nfs /lib/librpc.so 192.168.0.1:/data/
```

Remove the NFS Userspacetools package via 

```sh
$ opkg --autoremove remove nfs-utils
```

If you can you should reset your full flash and all configuration to free everything you can via "mtd -r erase rootfs_data". If you can not do this, may not enough is freed and you will stuck because of memory.

## Install kernel support for NFS.

```sh
$ opkg update
$ opkg install kmod-fs-nfs
´´´

## Copy stored userlevel files to /tmp and link them to system:

```sh
# Example:
$ scp 192.168.0.1:/data/mount.nfs 192.168.0.1:/data/librpc.so /tmp/
```

```sh
$ ln -s /tmp/mount.nfs /sbin/
$ ln -s /tmp/librpc.so /lib/
```

## Mount NFS Share from remote storage to /mnt/nfsroot/

```sh
$ mkdir /mnt/nfsroot/
$ mount.nfs -o rw,nolock,tcp,v3 NFSSERVER:DATAPATH /mnt/nfsroot/
```

```sh
# Example:
$ mount.nfs -o rw,nolock,tcp,v3 192.168.0.1:/data/openwrt/ /mnt/nfsroot/
```

## Overlay system with your NFS and jump into it:

```sh
$ mkdir /newroot
$ mount -o lowerdir=/,upperdir=/mnt/nfsroot/ -t overlayfs overlayfs:/mnt/nfsroot /newroot
$ for i in proc dev sys rom tmp; do mount --rbind /$i /newroot/$i; done
$ chroot /newroot
```

## Install OpenVPN and whatever you want to. But be aware: You are wasting RAM of your OpenWRT!

```sh
$ opkg update
$ opkg install openvpn-openssl
```

## Exit chroot and remove kernel modules for NFS, if you do not need 

```sh
$ exit
$ opkg --autoremove remove kmod-fs-nfs
```

If you can you should reset your full flash and all configuration to free everything you can via "mtd -r erase rootfs_data". If you can not do this, may not enough is freed and you will stuck because of memory.

## On NFS Server you can tar your OpenVPN:

```sh
$ cd /data/openwrt
$ tar -czvf ../openvpn.14.07.tar.gz *
$ scp ../openvpn.14.07.tar.gz YOURGW:/home/dynloader/
```

## Create a sshkey on your OpenWRT, and enter the public part to /home/dynloader/.ssh/authorized_keys the following:

```
command="cat ~/openvpn.14.07.tar.gz",no-pty,no-port-forwarding,no-x11-forwarding,no-agent-forwarding ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCH799uwlMwzAWOt/ZUF1Ml6wCFEL5xnNI4YDs8nVoMg2hav05WOQUDPyXHVwA3qhZ6Grx2avUkACcJisrqHk6Esyzq9+SwA+KSEyoWlAFfS83PL5JTDrjm094fHHakp93unpXSeekyJjh38d8POWi7uscr7TLw2sKF04ndC/H1W526/0u9Wl91yU1dC0OL/DmY+CuISnKTOTgcUDAgNcbgNNxboKJQ6GsJTGQprEcqPl0C3RFuIyaBATdtVnLGUEU6EJmuJ5IRkkr/pptc/6+28z3nF6jVMlEu46avdM3e8e/OHpkuOiNrvAh9QLW0tAZFn+W1OdjcqHeUtKcBpS4Z
```

