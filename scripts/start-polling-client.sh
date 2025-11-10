#!/bin/bash
# Skrypt do uruchomienia klienta polling

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Aktywuj virtual environment jeśli istnieje
if [ -d "$PROJECT_DIR/venv" ]; then
    source "$PROJECT_DIR/venv/bin/activate"
fi

# Ustaw zmienne środowiskowe
export POLLING_SERVER_URL=${POLLING_SERVER_URL:-"https://waldus-server.com"}
export POLLING_INTERVAL=${POLLING_INTERVAL:-5}

echo "🚀 Uruchamianie klienta polling..."
echo "   Serwer: $POLLING_SERVER_URL"
echo "   Interwał: ${POLLING_INTERVAL}s"
echo ""

cd "$PROJECT_DIR"
python3 -m src.polling.client \
    --server "$POLLING_SERVER_URL" \
    --interval "$POLLING_INTERVAL"

