#!/bin/bash
# Szybkie sprawdzenie statusu WireGuard i diagnostyka

echo "🔍 Diagnostyka WireGuard VPN"
echo "============================"
echo ""

# Sprawdź czy WireGuard jest zainstalowany
if ! command -v wg >/dev/null 2>&1; then
    echo "❌ WireGuard nie jest zainstalowany"
    exit 1
fi

echo "✅ WireGuard zainstalowany"
echo ""

# Sprawdź status
echo "📊 Status WireGuard:"
WG_STATUS=$(wg show 2>&1)
if [ -z "$WG_STATUS" ]; then
    echo "❌ WireGuard nie jest uruchomiony"
    echo ""
    echo "💡 Aby uruchomić:"
    echo "   sudo wg-quick up ~/.wireguard/wg0.conf"
else
    echo "✅ WireGuard działa:"
    echo "$WG_STATUS"
fi
echo ""

# Sprawdź konfigurację
CONFIG_FILE="$HOME/.wireguard/wg0.conf"
if [ -f "$CONFIG_FILE" ]; then
    echo "📝 Konfiguracja: $CONFIG_FILE"
    if grep -q "<SERVER_PUBLIC_KEY>" "$CONFIG_FILE"; then
        echo "❌ Konfiguracja nie jest uzupełniona - brak klucza serwera"
        echo ""
        echo "💡 Uzupełnij konfigurację:"
        echo "   ./scripts/complete-wireguard.sh <SERVER_PUBLIC_KEY>"
    else
        echo "✅ Konfiguracja wygląda poprawnie"
    fi
else
    echo "❌ Plik konfiguracji nie istnieje: $CONFIG_FILE"
fi
echo ""

# Test połączenia
echo "🧪 Test połączenia:"
SERVER_IP="10.0.0.1"
if ping -c 1 -W 2 "$SERVER_IP" >/dev/null 2>&1; then
    echo "✅ Ping do $SERVER_IP działa"
else
    echo "❌ Ping do $SERVER_IP nie działa"
fi

if curl -s --max-time 5 "http://$SERVER_IP:11434/api/tags" >/dev/null 2>&1; then
    echo "✅ Ollama dostępne na http://$SERVER_IP:11434"
else
    echo "❌ Ollama nie odpowiada na http://$SERVER_IP:11434"
fi
echo ""

# Sprawdź logi
LOG_FILE="$HOME/.wireguard/logs/wireguard.log"
if [ -f "$LOG_FILE" ]; then
    echo "📋 Ostatnie logi (ostatnie 5 linii):"
    tail -5 "$LOG_FILE"
    echo ""
    echo "💡 Pełne logi: cat $LOG_FILE"
else
    echo "⚠️  Brak pliku logów: $LOG_FILE"
    echo "💡 Uruchom logger: ./scripts/wireguard-logger.sh"
fi
echo ""

echo "💡 Pełna diagnostyka: ./scripts/wireguard-logger.sh"

