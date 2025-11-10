#!/bin/bash
# Skrypt do konfiguracji WireGuard na serwerze OVH
# Uruchom ten skrypt NA SERWERZE OVH

set -e

echo "🔐 Konfiguracja WireGuard na serwerze OVH"
echo "========================================="
echo ""

# Sprawdź czy jesteś root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Uruchom skrypt jako root (sudo)"
    exit 1
fi

# Sprawdź czy WireGuard jest zainstalowany
if ! command -v wg &> /dev/null; then
    echo "📥 Instalowanie WireGuard..."
    apt update
    apt install -y wireguard wireguard-tools
fi

echo "✅ WireGuard zainstalowany"
echo ""

# Pobierz dane
read -p "Podaj WireGuard IP serwera (np. 10.0.0.1): " SERVER_WG_IP
read -p "Podaj WireGuard IP lokalnego PC (np. 10.0.0.2): " LOCAL_WG_IP
read -p "Podaj publiczny klucz lokalnego PC: " LOCAL_PUBLIC_KEY
read -p "Podaj port WireGuard (domyślnie 51820): " WG_PORT
WG_PORT=${WG_PORT:-51820}

# Generuj klucze serwera
echo ""
echo "🔑 Generowanie kluczy serwera..."
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)

echo "✅ Klucze wygenerowane"
echo ""
echo "📋 Publiczny klucz serwera (skopiuj go):"
echo "$SERVER_PUBLIC_KEY"
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

# Włącz IP forwarding
echo "📝 Włączanie IP forwarding..."
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -p > /dev/null

echo "✅ IP forwarding włączony"
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
echo "📋 Informacje do konfiguracji lokalnej:"
echo "   Publiczny klucz serwera: $SERVER_PUBLIC_KEY"
echo "   WireGuard IP serwera: $SERVER_WG_IP"
echo "   Port WireGuard: $WG_PORT"
echo ""
echo "💡 Na lokalnym PC użyj tych danych w setup-wireguard-ovh.sh"

