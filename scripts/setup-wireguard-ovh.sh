#!/bin/bash
# Skrypt do konfiguracji WireGuard VPN między lokalnym PC a serwerem OVH
# Najlepsze rozwiązanie - profesjonalne, bezpieczne, szybkie

set -e

echo "🔐 Konfiguracja WireGuard VPN z serwerem OVH"
echo "==========================================="
echo ""

# Sprawdź czy jesteś root (dla Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]] && [ "$EUID" -ne 0 ]; then 
    echo "❌ Uruchom skrypt jako root (sudo)"
    exit 1
fi

# Sprawdź system operacyjny
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    echo "📦 System: MacOS"
    
    # Sprawdź czy WireGuard jest zainstalowany
    if ! command -v wg &> /dev/null; then
        echo "📥 Instalowanie WireGuard..."
        if command -v brew &> /dev/null; then
            brew install wireguard-tools
        else
            echo "❌ Homebrew nie jest zainstalowany"
            exit 1
        fi
    fi
    
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    echo "📦 System: Linux"
    
    # Instalacja WireGuard
    if ! command -v wg &> /dev/null; then
        echo "📥 Instalowanie WireGuard..."
        apt update
        apt install -y wireguard wireguard-tools
    fi
else
    echo "❌ Nieobsługiwany system operacyjny"
    exit 1
fi

echo "✅ WireGuard zainstalowany"
echo ""

# Sprawdź czy parametry zostały podane jako argumenty
if [ $# -ge 1 ]; then
    OVH_SERVER=$1
    SSH_USER=${2:-$(whoami)}
    SSH_PORT=${3:-22}
    echo "📝 Używam parametrów z linii poleceń:"
    echo "   Serwer: $OVH_SERVER"
    echo "   Użytkownik: $SSH_USER"
    echo "   Port SSH: $SSH_PORT"
    echo ""
else
    # Pobierz dane od użytkownika
    read -p "Podaj adres serwera OVH (np. server.example.com lub IP): " OVH_SERVER
    read -p "Podaj użytkownika SSH (domyślnie $(whoami)): " SSH_USER
    SSH_USER=${SSH_USER:-$(whoami)}
    read -p "Podaj port SSH (domyślnie 22): " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}
fi

# Generuj klucze
WG_DIR="$HOME/.wireguard"
mkdir -p $WG_DIR

echo ""
echo "🔑 Generowanie kluczy WireGuard..."
echo ""

# Klucz prywatny lokalny
LOCAL_PRIVATE_KEY=$(wg genkey)
LOCAL_PUBLIC_KEY=$(echo $LOCAL_PRIVATE_KEY | wg pubkey)

# Klucz prywatny serwera (będzie wygenerowany na serwerze)
echo "📝 Skonfiguruj serwer OVH:"
echo ""
echo "1. Zaloguj się na serwer OVH:"
echo "   ssh $SSH_USER@$OVH_SERVER"
echo ""
echo "2. Zainstaluj WireGuard:"
echo "   apt update && apt install -y wireguard wireguard-tools"
echo ""
echo "3. Włącz IP forwarding:"
echo "   echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf"
echo "   sysctl -p"
echo ""
echo "4. Utwórz klucze na serwerze:"
echo "   wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key"
echo ""
echo "5. Skopiuj publiczny klucz serwera i wklej tutaj:"
read -p "   Publiczny klucz serwera: " SERVER_PUBLIC_KEY
echo ""
read -p "   WireGuard IP serwera (np. 10.0.0.1): " SERVER_WG_IP
read -p "   WireGuard IP lokalnego PC (np. 10.0.0.2): " LOCAL_WG_IP
read -p "   Port WireGuard na serwerze (domyślnie 51820): " WG_PORT
WG_PORT=${WG_PORT:-51820}

# Generuj konfigurację lokalną
LOCAL_CONFIG="$WG_DIR/wg0.conf"
cat > $LOCAL_CONFIG <<EOF
[Interface]
PrivateKey = $LOCAL_PRIVATE_KEY
Address = $LOCAL_WG_IP/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $OVH_SERVER:$WG_PORT
AllowedIPs = $SERVER_WG_IP/32, 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "✅ Utworzono konfigurację lokalną: $LOCAL_CONFIG"
echo ""

# Generuj konfigurację serwera (do skopiowania)
SERVER_CONFIG="/tmp/wg0-server.conf"
cat > $SERVER_CONFIG <<EOF
[Interface]
PrivateKey = <PRIVATE_KEY_SERVER>  # Wklej klucz prywatny z serwera
Address = $SERVER_WG_IP/24
ListenPort = $WG_PORT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $LOCAL_PUBLIC_KEY
AllowedIPs = $LOCAL_WG_IP/32
EOF

echo "📝 Konfiguracja serwera zapisana w: $SERVER_CONFIG"
echo ""
echo "📋 Następne kroki:"
echo ""
echo "1. Skopiuj konfigurację serwera na OVH:"
echo "   scp $SERVER_CONFIG $SSH_USER@$OVH_SERVER:/etc/wireguard/wg0.conf"
echo ""
echo "2. Na serwerze OVH:"
echo "   - Edytuj /etc/wireguard/wg0.conf i wklej klucz prywatny serwera"
echo "   - Włącz service: systemctl enable wg-quick@wg0"
echo "   - Uruchom: systemctl start wg-quick@wg0"
echo ""
echo "3. Lokalnie (MacOS):"
echo "   sudo wg-quick up $LOCAL_CONFIG"
echo ""
echo "   Lub (Linux):"
echo "   sudo wg-quick up wg0"
echo ""
echo "4. Sprawdź połączenie:"
echo "   ping $SERVER_WG_IP"
echo ""
echo "5. Na serwerze OVH, Ollama będzie dostępne na:"
echo "   http://$SERVER_WG_IP:11434 (przez VPN)"
echo "   lub skonfiguruj Nginx reverse proxy z SSL (zobacz setup-nginx-ovh.sh)"

