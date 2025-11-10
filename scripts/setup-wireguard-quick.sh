#!/bin/bash
# Szybka konfiguracja WireGuard - automatyczna
# Uruchamia konfigurację lokalną i przygotowuje instrukcje dla serwera

set -e

echo "🔐 Szybka konfiguracja WireGuard VPN"
echo "===================================="
echo ""

# Parametry
OVH_SERVER=${1:-waldus-server}
SSH_USER=${2:-waldusz}
SERVER_WG_IP=${3:-10.0.0.1}
LOCAL_WG_IP=${4:-10.0.0.2}
WG_PORT=${5:-51820}

echo "📝 Konfiguracja:"
echo "   Serwer: $SSH_USER@$OVH_SERVER"
echo "   IP serwera: $SERVER_WG_IP"
echo "   IP lokalne: $LOCAL_WG_IP"
echo "   Port: $WG_PORT"
echo ""

# Generuj klucze lokalne
WG_DIR="$HOME/.wireguard"
mkdir -p $WG_DIR

echo "🔑 Generowanie kluczy lokalnych..."
LOCAL_PRIVATE_KEY=$(wg genkey)
LOCAL_PUBLIC_KEY=$(echo $LOCAL_PRIVATE_KEY | wg pubkey)

echo "✅ Klucze wygenerowane"
echo "   Publiczny klucz lokalny: $LOCAL_PUBLIC_KEY"
echo ""

# Sprawdź czy WireGuard jest zainstalowany
if ! command -v wg &> /dev/null; then
    echo "❌ WireGuard nie jest zainstalowany"
    exit 1
fi

# Utworzenie konfiguracji lokalnej (bez klucza serwera - będzie dodany później)
LOCAL_CONFIG="$WG_DIR/wg0.conf"
cat > $LOCAL_CONFIG <<EOF
[Interface]
PrivateKey = $LOCAL_PRIVATE_KEY
Address = $LOCAL_WG_IP/24
DNS = 1.1.1.1

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>  # Zostanie uzupełnione po konfiguracji serwera
Endpoint = $OVH_SERVER:$WG_PORT
AllowedIPs = $SERVER_WG_IP/32
PersistentKeepalive = 25
EOF

echo "✅ Utworzono konfigurację lokalną: $LOCAL_CONFIG"
echo ""

# Przygotuj instrukcje dla serwera
echo "📋 INSTRUKCJE DLA SERWERA OVH:"
echo ""
echo "1. Zaloguj się na serwer:"
echo "   ssh $SSH_USER@$OVH_SERVER"
echo ""
echo "2. Uruchom te komendy (wymaga root):"
echo ""
echo "   # Instalacja WireGuard"
echo "   apt update && apt install -y wireguard wireguard-tools"
echo ""
echo "   # Włącz IP forwarding"
echo "   echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf"
echo "   sysctl -p"
echo ""
echo "   # Generuj klucze"
echo "   wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key"
echo ""
echo "   # Pokaż publiczny klucz serwera (skopiuj go):"
echo "   cat /etc/wireguard/public.key"
echo ""
echo "   # Utwórz konfigurację (zamień <LOCAL_PUBLIC_KEY> na klucz poniżej):"
echo "   cat > /etc/wireguard/wg0.conf <<'WGEOF'"
echo "   [Interface]"
echo "   PrivateKey = \$(cat /etc/wireguard/private.key)"
echo "   Address = $SERVER_WG_IP/24"
echo "   ListenPort = $WG_PORT"
echo "   PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
echo "   PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE"
echo ""
echo "   [Peer]"
echo "   PublicKey = $LOCAL_PUBLIC_KEY"
echo "   AllowedIPs = $LOCAL_WG_IP/32"
echo "   WGEOF"
echo ""
echo "   # Włącz i uruchom WireGuard"
echo "   systemctl enable wg-quick@wg0"
echo "   systemctl start wg-quick@wg0"
echo ""
echo "3. Po skonfigurowaniu serwera, wróć tutaj i uruchom:"
echo "   ./scripts/complete-wireguard.sh <SERVER_PUBLIC_KEY>"
echo ""

