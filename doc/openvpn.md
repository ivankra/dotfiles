# OpenVPN quick setup on Debian/Ubuntu

## CA setup

Good practice would be to run these steps on a separate host.

Download EasyRSA:

```shell
$ wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.4/EasyRSA-3.0.4.tgz
$ sha256sum EasyRSA-3.0.4.tgz
472167f976c6cb7c860cec6150a5616e163ae20365c81f179811d6ee0779ec5a  EasyRSA-3.0.4.tgz
$ tar xf EasyRSA-3.0.4.tgz
$ rm -f EasyRSA-3.0.4.tgz
$ mv EasyRSA-3.0.4 easyrsa
$ chmod 0700 easyrsa
$ cd easyrsa
$ mv vars.example vars
$ git init
$ git add .
$ git commit -a -m 'Initial commit'
$ vim vars
Optional, maybe edit REQ_* vars, change algo to ec, etc.
$ sudo apt install openvpn              # for generating tls key
```

Initialize CA, generate VPN server certificate and keys:

```shell
$ ./easyrsa init-pki
$ ./easyrsa build-ca
$ ./easyrsa build-server-full server nopass
$ ./easyrsa gen-dh
$ mkdir server
$ cp pki/ca.crt pki/issued/server.crt pki/private/server.key pki/dh.pem server/
$ /usr/sbin/openvpn --genkey --secret server/tls.key
```

Distribute `server/*` to the server host.

Create client certificate, keys and config, repeat for each new client:

```shell
$ SERVER=123.45.67.89                   # VPN server's IP or DNS name
$ CLIENT=client1                        # some unique id for this client
$ ./easyrsa build-client-full $CLIENT
$ cat >$CLIENT.ovpn <<EOF
client
dev tun
remote $SERVER 1194 udp
tls-client
nobind
persist-key
persist-tun
verb 3
cipher AES-256-CBC
auth SHA512
remote-cert-tls server
compress lz4-v2                         # not stricly needed but avoids a warning
mssfix 1200                             # lower default for best reliability
pull
<ca>
$(cat pki/ca.crt)
</ca>
<cert>
$(cat pki/issued/$CLIENT.crt)
</cert>
<key>
$(cat pki/private/$CLIENT.key)
</key>
<tls-crypt>
$(cat server/tls.key)
</tls-crypt>
EOF
$ tar -cf $CLIENT.tar $CLIENT.ovpn pki/issued/$CLIENT.crt pki/private/$CLIENT.key pki/ca.crt server/tls.key
```

Distribute `$CLIENT.ovpn` or `$CLIENT.tar` to the client.

## Server setup

Install package and add a separate user and directory for running openvpn:

```shell
$ apt install openvpn
$ adduser --system --group openvpn
$ mkdir -p /var/lib/openvpn/tmp
$ touch /var/lib/openvpn/{udp.ipp,tcp.ipp}
$ chown openvpn:openvpn /var/lib/openvpn/{,tmp,*.ipp}
```

Copy `server/*` from CA host to VPN server host into `/etc/openvpn/server/`.
Create config `/etc/openvpn/server/udp.conf`. Sample config, assuming recent
client and server versions:

```
port 1194
proto udp
dev tun0
persist-key
persist-tun
max-clients 120
keepalive 300 900                           # ping every 5 min, inactivity restart 15 min
float
dh dh.pem
ca ca.crt
cert server.crt
key server.key
tls-crypt tls.key
script-security 2
cipher AES-256-CBC
auth SHA512
tls-server
tls-version-min 1.2
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384
ncp-ciphers AES-256-GCM
mute 10
ifconfig-pool-persist /var/lib/openvpn/udp.ipp
server 192.168.10.0 255.255.255.128         # enable IPv4 with this address range
push "dhcp-option DNS 192.168.0.2"          # specify your DNS server, or 8.8.8.8
push "redirect-gateway def1 bypass-dhcp"    # redirect all IPv4
server-ipv6 fc00:1::/64                     # enable IPv6
push "route-ipv6 2000::/3"                  # redirect IPv6 traffic for blackholing it
user openvpn
group openvpn
chroot /var/lib/openvpn
status /var/lib/openvpn/udp.status 1
status-version 3
log-append /var/lib/openvpn/udp.log
verb 5
compress lz4-v2
push "compress lz4-v2"
mssfix 1200
push "mssfix 1200"
```

Create a config for TCP server `/etc/openvpn/server/tcp.conf` based on
UDP config with some changes:

```
proto tcp
dev tun1
ifconfig-pool-persist /var/lib/openvpn/tcp.ipp
server 192.168.10.128 255.255.255.128
server-ipv6 fc00:2::/64
status /var/lib/openvpn/tcp.status 1
log-append /var/lib/openvpn/tcp.log
```

Configure firewall to do NAT and bring the server up:

```shell
$ vim /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=0   # blackhole IPv6
$ sysctl -p
$ apt install iptables-persistent
$ iptables -A INPUT --dport 1194 -j ACCEPT
$ iptables -A FORWARD -s 192.168.10.0/24 -j ACCEPT
$ iptables -A FORWARD -d 192.168.10.0/24 -j ACCEPT
$ iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -j MASQUERADE
$ iptables-save >/etc/iptables/rules.v4
$ chmod a+rx /etc/openspn/server/client-connect.sh
$ systemctl enable openvpn-server@tcp && systemctl start openvpn-server@tcp
$ systemctl enable openvpn-server@udp && systemctl start openvpn-server@udp
```

## Client setup

Android apps:

  * Open source:
    [OpenVPN for Android](https://play.google.com/store/apps/details?id=de.blinkt.openvpn&hl=en)
    ([source](https://github.com/schwabe/ics-openvpn))
  * Official closed source client:
    [OpenVPN Connect](https://play.google.com/store/apps/details?id=net.openvpn.openvpn&hl=en)

Check DNS, WebRTC, IPv6 address leaks.
