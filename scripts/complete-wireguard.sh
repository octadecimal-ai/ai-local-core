#!/bin/bash
# Dokończenie konfiguracji WireGuard po skonfigurowaniu serwera

set -e

if [ $# -lt 1 ]; then
    echo "❌ Użycie: $0 <SERVER_PUBLIC_KEY> [SERVER_WG_IP] [LOCAL_WG_IP]"
    exit 1
fi

SERVER_PUBLIC_KEY=$1
SERVER_WG_IP=${2:-10.0.0.1}
LOCAL_WG_IP=${3:-10.0.0.2}

WG_DIR="$HOME/.wireguard"
LOCAL_CONFIG="$WG_DIR/wg0.conf"

if [ ! -f "$LOCAL_CONFIG" ]; then
    echo "❌ Konfiguracja lokalna nie istnieje. Uruchom najpierw setup-wireguard-quick.sh"
    exit 1
fi

echo "🔐 Dokończenie konfiguracji WireGuard"
echo "===================================="
echo ""

# Aktualizuj konfigurację z kluczem serwera
sed -i.bak "s|<SERVER_PUBLIC_KEY>|$SERVER_PUBLIC_KEY|g" $LOCAL_CONFIG

echo "✅ Zaktualizowano konfigurację: $LOCAL_CONFIG"
echo ""

# Uruchom WireGuard
echo "🚀 Uruchamianie WireGuard..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    sudo wg-quick up $LOCAL_CONFIG
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo wg-quick up wg0
fi

echo "✅ WireGuard uruchomiony"
echo ""

# Sprawdź status
echo "📊 Status WireGuard:"
wg show
echo ""

# Test połączenia
echo "🧪 Test połączenia..."
if ping -c 1 -W 2 $SERVER_WG_IP > /dev/null 2>&1; then
    echo "✅ Ping do serwera działa!"
else
    echo "⚠️  Ping nie działa - sprawdź konfigurację"
fi

echo ""
echo "💡 Ollama będzie dostępne na serwerze OVH pod adresem:"
echo "   http://$SERVER_WG_IP:11434"
echo ""
echo "📋 Konfiguracja w Waldus API (.env):"
echo "   OLLAMA_URL=http://$SERVER_WG_IP:11434"
echo ""

