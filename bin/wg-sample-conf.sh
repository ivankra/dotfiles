#!/bin/bash
set -e -o pipefail

PRI1=$(wg genkey)
PUB1=$(echo "$PRI1" | wg pubkey)

PRI2=$(wg genkey)
PUB2=$(echo "$PRI2" | wg pubkey)

PSK=$(wg genpsk)

cat <<EOF
#=== SERVER CONFIG ===
# copy to /etc/wireguard/xxx.conf
# systemctl enable wg-quick@xxx
# enable forwarding
# enable masquerading

[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $PRI1
#PublicKey = $PUB1

[Peer]
PublicKey = $PUB2
PresharedKey = $PSK
AllowedIPs = 10.0.0.2/32  # route these IPs to peer


=== CLIENT CONFIG ===

[Interface]
Address = 10.0.0.2/24
ListenPort = 51820
PrivateKey = $PRI2
#PublicKey = $PUB2
#DNS = x.x.x.x            # install openresolv or resolvconf

[Peer]
PublicKey = $PUB1
PresharedKey = $PSK
AllowedIPs = 10.0.0.1/24  # route this net to peer
#AllowedIPs = 0.0.0.0/0   # route everything through peer
EndPoint = <server>:51820
PersistentKeepalive = 25

EOF
