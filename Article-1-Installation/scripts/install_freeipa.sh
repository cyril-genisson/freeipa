#!/usr/bin/env bash

# Variables de configuration pour FreeIPA
# A MODIFIER EN FONCTION DES BESOINS
DIRECTORY_PASSWD="P@ssWord!"
ADMIN_PASSWD="P@ssWord!"
HOSTNAME=ipa1.labo.lan
ZONE=labo.lan
REALM=LABO.LAN
NETBIOS=LABOLAN
IP_ADDR="192.168.122.2/24"
NTP_SERVER="192.168.122.2"
GATEWAY="192.168.122.1"
DNS1="127.0.0.1"
DNS2="8.8.8.8"

# Récupération de les informations de la première interface réseau disponible
CONNECTION=$(nmcli connection | grep ethernet | cut -d' ' -f1)
DEVICE=$(nmcli device | grep ethernet | cut -d' ' -f1)
CON_IPA="FreeIPA-Connection"


# Installation des paquets nécessaires
dnf install -y freeipa-server freeipa-server-dns rng-tools &&

# Active le service d'amélioration d'entropie
systemctl enable --now rngd

# Définition du hostname
hostnamectl hostname $HOSTNAME &&

# Configuration du réseau
nmcli con down "$CONNECTION" &&
nmcli con del "$CONNECTION" &&
nmcli con add con-name $CON_IPA ifname "$DEVICE" type ethernet &&
nmcli con modify $CON_IPA ipv4.method manual ipv4.addresses $IP_ADDR ipv4.gateway $GATEWAY &&
nmcli con modify $CON_IPA ipv4.dns "$DNS1 $DNS2" &&
nmcli con modify $CON_IPA ipv4.dns-search $ZONE &&
nmcli con modify $CON_IPA ipv6.method disabled autoconnect yes 

# Configuration du pare-feux
firewall-cmd --permanent --add-service={freeipa-4,freeipa-replication,dns,ntp} &&
firewall-cmd --reload &&

# Autorise les clients du réseau à l'accès du serveur de temps
# sur le réseau local
sed -i 's/^#allow.*/allow\ 192.168.122.0\/24/g' /etc/chrony.conf &&
systemctl restart chronyd &&

ipa-server-install --skip-mem-check --unattended \
--ds-password=$DIRECTORY_PASSWD \
--admin-password=$ADMIN_PASSWD \
--realm="$REALM" \
--netbios-name="$NETBIOS" \
--hostname=$HOSTNAME \
--setup-kra \
--setup-dns \
--mkhomedir \
--ntp-server="$NTP_SERVER" \
--ssh-trust-dns \
--auto-reverse \
--auto-forwarders
