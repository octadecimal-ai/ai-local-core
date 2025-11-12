#!/bin/bash
# Główny skrypt do uruchomienia serwera API i klienta polling
# Restartuje serwer API, a następnie uruchamia klienta polling PHP

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

cd "$PROJECT_DIR"

echo "🚀 Uruchamianie serwera API i klienta polling..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Krok 1: Restart serwera API
echo "📡 Krok 1: Restart serwera API..."
"$PROJECT_DIR/scripts/restart-api-server.sh"
echo ""

# Krótka przerwa, aby serwer się uruchomił
sleep 2

# Krok 2: Uruchom klienta polling
echo "🔄 Krok 2: Uruchamianie klienta polling..."
echo ""

# Sprawdź czy plik istnieje
if [ ! -f "$PROJECT_DIR/src/ollama/ollama-polling-client.php" ]; then
    echo "❌ Błąd: Nie znaleziono pliku src/ollama/ollama-polling-client.php"
    exit 1
fi

# Uruchom klienta polling PHP
php "$PROJECT_DIR/src/ollama/ollama-polling-client.php"

