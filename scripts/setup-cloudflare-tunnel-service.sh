#!/bin/bash
# Skrypt do konfiguracji Cloudflare Tunnel jako systemd service (Ubuntu Server)
# Dla produkcyjnego użycia

set -e

echo "🔧 Konfiguracja Cloudflare Tunnel jako systemd service"
echo "=================================================="
echo ""

# Sprawdź czy jesteś root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Uruchom skrypt jako root (sudo)"
    exit 1
fi

# Sprawdź czy cloudflared jest zainstalowany
if ! command -v cloudflared &> /dev/null; then
    echo "❌ cloudflared nie jest zainstalowany. Uruchom najpierw setup-cloudflare-tunnel.sh"
    exit 1
fi

# Katalog dla konfiguracji
CONFIG_DIR="/etc/cloudflared"
SERVICE_USER="ollama"

echo "📁 Tworzenie katalogu konfiguracyjnego: $CONFIG_DIR"
mkdir -p $CONFIG_DIR

echo ""
echo "📝 Konfiguracja tunelu..."
echo ""
read -p "Podaj nazwę tunelu (np. ollama-tunnel): " TUNNEL_NAME
read -p "Podaj port lokalny Ollama (domyślnie 11434): " OLLAMA_PORT
OLLAMA_PORT=${OLLAMA_PORT:-11434}

# Utworzenie pliku konfiguracyjnego
CONFIG_FILE="$CONFIG_DIR/config.yml"
cat > $CONFIG_FILE <<EOF
tunnel: $TUNNEL_NAME
credentials-file: $CONFIG_DIR/$TUNNEL_NAME.json

ingress:
  - hostname: ollama.yourdomain.com  # Zmień na swoją domenę
    service: http://localhost:$OLLAMA_PORT
  - service: http_status:404
EOF

echo "✅ Utworzono plik konfiguracyjny: $CONFIG_FILE"
echo ""
echo "📝 Edytuj $CONFIG_FILE i zmień hostname na swoją domenę"
echo ""

# Utworzenie systemd service
SERVICE_FILE="/etc/systemd/system/cloudflared.service"
cat > $SERVICE_FILE <<EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
ExecStart=/usr/local/bin/cloudflared tunnel --config $CONFIG_FILE run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Utworzono systemd service: $SERVICE_FILE"
echo ""
echo "📝 Następne kroki:"
echo "   1. Zaloguj się do Cloudflare: cloudflared tunnel login"
echo "   2. Utwórz tunnel: cloudflared tunnel create $TUNNEL_NAME"
echo "   3. Skonfiguruj DNS w Cloudflare Dashboard"
echo "   4. Edytuj $CONFIG_FILE i ustaw hostname"
echo "   5. Włącz service: sudo systemctl enable cloudflared"
echo "   6. Uruchom service: sudo systemctl start cloudflared"
echo ""

