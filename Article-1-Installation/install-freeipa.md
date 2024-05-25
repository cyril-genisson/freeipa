# Installation d'un serveur FreeIPA

````bash
cat > install_freeipa << EOF
#!/usr/bin/env bash

# Récupération de la première interface réseau disponible
CONNECTION=$(nmcli connection | grep ethernet | cut -d' ' -f1)
DEVICE=$(nmcli device | grep ethernet | cut -d' ' -f1)
CON_IPA="FreeIPA-Connection"

# Variables de configuration pour FreeIPA
DIRECTORY_PASSWD=""
ADMIN_PASSWD=""
HOSTNAME=ipa1.labo.lan
ZONE=labo.lan
REALM= LABO.LAN
NETBIOS=LABOLAN
IP_ADDR="192.168.1.3/24"
GATEWAY=192.168.1.1
DNS1="127.0.0.1"
DNS2="8.8.8.8"

# Installation des paquets nécessaires
dnf install -y freeipa-server freeipa-server-dns &&

# Définition du hostname
hostnamectl hostname $HOSTNAME

# Configuration du réseau
nmcli con down $CONNECTION
nmcli con del $CONNECTION
nmcli con add con-name $CON_IPA ifname $DEVICE type ethernet
nmcli con modify $CON_IPA ipv4.method manual
nmcli con modify $CON_IPA ipv4.addresses $IP_ADDR
nmcli con modify $CON_IPA ipv4.gateway $GATEWAY
nmcli con modify $CON_IPA ipv4.dns "$DNS1" "$DNS2"
nmcli con modify $CON_IPA ipv4.dns-search $ZONE
nmcli con up $CON_IPA

# Configuration du pare-feux
SERVICES="freeipa-4,freeipa-replication,dns,ntp"
firewall-cmd --permanent --add-service={$SERVICES}
firewall-cmd --reload

# Autorise les clients du réseau à l'accès du serveur de temps
# sur le réseau local
sed 's/^#allow.*/allow\ 192.168.1.0\/24/g' /etc/chrony.cfg
systemctl restart chronyd

ipa-server-install --unattended \
--ds-password= DIRECTORY_PASSWD \
--admin-password= ADMIN_PASSWD \
--domain= $DOMAIN\
--realm= $REALM\
--netbios-name= $NETBIOS_NAME
--hostname= $HOSTNAME\
--setup-kra \
--setup-dns \
--mkhomedir \
--ntp-server=192.168.1.3 \
--ssh-trust-dns \
--auto-reverse \
--auto-forwarders
EOF

chmod +x install_freeipa
./install_freeipa

````