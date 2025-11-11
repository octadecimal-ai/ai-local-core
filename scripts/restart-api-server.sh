#!/bin/bash
# Skrypt do uruchomienia serwera API (z restartem jeśli działa)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"

mkdir -p "$LOG_DIR"

cd "$PROJECT_DIR"

# Aktywuj virtual environment jeśli istnieje
if [ -d "$PROJECT_DIR/venv" ]; then
    source "$PROJECT_DIR/venv/bin/activate"
fi

# Zatrzymaj poprzednie instancje serwera
EXISTING_PIDS="$(pgrep -f "src/api/server.py" || true)"
if [ -n "$EXISTING_PIDS" ]; then
    echo "🔄 Wykryto działający serwer API (PID: $EXISTING_PIDS). Zatrzymuję..."
    kill $EXISTING_PIDS || true
    sleep 2
fi

PORT="${PORT:-5001}"
HOST="${HOST:-127.0.0.1}"

echo "🚀 Uruchamiam serwer API na ${HOST}:${PORT}..."
nohup env PORT="$PORT" HOST="$HOST" python3 "$PROJECT_DIR/src/api/server.py" >> "$LOG_DIR/api-server.log" 2>&1 &
NEW_PID=$!

echo "✅ Serwer API działa w tle (PID: $NEW_PID)"
echo "📄 Logi: $LOG_DIR/api-server.log"
echo "🌐 Endpoint: http://${HOST}:${PORT}"

