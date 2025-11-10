#!/bin/bash
# Skrypt do wyświetlenia lokalnego klucza publicznego WireGuard

CONFIG_FILE="$HOME/.wireguard/wg0.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Plik konfiguracji nie istnieje: $CONFIG_FILE"
    exit 1
fi

# Wyciągnij klucz prywatny
PRIVATE_KEY=$(grep "PrivateKey" "$CONFIG_FILE" | sed 's/.*= *//' | sed 's/ *$//')

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Nie znaleziono klucza prywatnego w konfiguracji"
    exit 1
fi

# Wygeneruj klucz publiczny
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)

echo "📋 Twój lokalny klucz publiczny (ten idzie na serwer OVH):"
echo "$PUBLIC_KEY"
echo ""
echo "💡 Skopiuj ten klucz i użyj go w konfiguracji serwera:"
echo "   sudo bash /tmp/wireguard-server-config.sh $PUBLIC_KEY"
echo ""
echo "📝 Po skonfigurowaniu serwera, skopiuj klucz publiczny serwera i użyj:"
echo "   ./scripts/complete-wireguard.sh <SERVER_PUBLIC_KEY>"

