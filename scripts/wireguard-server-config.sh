#!/bin/bash
# Gotowy skrypt konfiguracyjny WireGuard dla serwera OVH
# Uruchom jako root na serwerze OVH
# 
# Użycie: bash wireguard-server-config.sh <LOCAL_PUBLIC_KEY>
#
# Przykład:
#   bash wireguard-server-config.sh i7sDWhlEpdaSZSHtvObKpXoeJOiIpzoN8cSP8BHO/X4=

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Uruchom skrypt jako root"
    exit 1
fi

if [ $# -lt 1 ]; then
    echo "❌ Użycie: $0 <LOCAL_PUBLIC_KEY>"
    echo "   Przykład: $0 i7sDWhlEpdaSZSHtvObKpXoeJOiIpzoN8cSP8BHO/X4="
    exit 1
fi

LOCAL_PUBLIC_KEY=$1
SERVER_WG_IP=${2:-10.0.0.1}
LOCAL_WG_IP=${3:-10.0.0.2}
WG_PORT=${4:-51820}

echo "🔐 Konfiguracja WireGuard na serwerze OVH"
echo "========================================="
echo ""
echo "📝 Parametry:"
echo "   IP serwera: $SERVER_WG_IP"
echo "   IP lokalne: $LOCAL_WG_IP"
echo "   Port: $WG_PORT"
echo "   Klucz lokalny: $LOCAL_PUBLIC_KEY"
echo ""

# Instalacja WireGuard
if ! command -v wg &> /dev/null; then
    echo "📥 Instalowanie WireGuard..."
    apt update
    apt install -y wireguard wireguard-tools
fi

echo "✅ WireGuard zainstalowany"
echo ""

# Generuj klucze serwera
echo "🔑 Generowanie kluczy serwera..."
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)

echo "✅ Klucze wygenerowane"
echo "📋 Publiczny klucz serwera (skopiuj go):"
echo "$SERVER_PUBLIC_KEY"
echo ""

# Włącz IP forwarding
echo "📝 Włączanie IP forwarding..."
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -p > /dev/null

echo "✅ IP forwarding włączony"
echo ""

# Utworzenie konfiguracji
WG_CONFIG="/etc/wireguard/wg0.conf"
cat > $WG_CONFIG <<EOF
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = $SERVER_WG_IP/24
ListenPort = $WG_PORT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $LOCAL_PUBLIC_KEY
AllowedIPs = $LOCAL_WG_IP/32
EOF

echo "✅ Utworzono konfigurację: $WG_CONFIG"
echo ""

# Włącz i uruchom WireGuard
echo "📝 Włączanie WireGuard service..."
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo "✅ WireGuard uruchomiony"
echo ""

# Sprawdź status
echo "📊 Status WireGuard:"
wg show
echo ""

echo "✅ Konfiguracja zakończona!"
echo ""
echo "📋 WAŻNE - Skopiuj ten klucz publiczny serwera:"
echo "$SERVER_PUBLIC_KEY"
echo ""
echo "💡 Użyj go w: ./scripts/complete-wireguard.sh $SERVER_PUBLIC_KEY"

