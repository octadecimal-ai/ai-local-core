#!/bin/bash
# Skrypt do konfiguracji SSH Tunnel przez serwer OVH
# Najprostsze rozwiązanie - używa istniejącego serwera jako tunelu

set -e

echo "🔐 Konfiguracja SSH Tunnel przez serwer OVH"
echo "=========================================="
echo ""

# Sprawdź czy autossh jest zainstalowany
if ! command -v autossh &> /dev/null; then
    echo "📥 Instalowanie autossh..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install autossh
        else
            echo "❌ Homebrew nie jest zainstalowany"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update
        sudo apt install -y autossh
    else
        echo "❌ Nieobsługiwany system"
        exit 1
    fi
fi

echo "✅ autossh zainstalowany"
echo ""

# Sprawdź czy parametry zostały podane jako argumenty
if [ $# -ge 1 ]; then
    # Parametry z linii poleceń
    OVH_SERVER=$1
    SSH_USER=${2:-$(whoami)}
    SSH_PORT=${3:-22}
    OLLAMA_PORT=${4:-11434}
    REMOTE_PORT=${5:-11434}
    echo "📝 Używam parametrów z linii poleceń:"
    echo "   Serwer: $OVH_SERVER"
    echo "   Użytkownik: $SSH_USER"
    echo "   Port SSH: $SSH_PORT"
    echo "   Port lokalny: $OLLAMA_PORT"
    echo "   Port zdalny: $REMOTE_PORT"
    echo ""
else
    # Pobierz dane od użytkownika
    read -p "Podaj adres serwera OVH (np. server.example.com lub IP): " OVH_SERVER
    read -p "Podaj użytkownika SSH (domyślnie $(whoami)): " SSH_USER
    SSH_USER=${SSH_USER:-$(whoami)}
    read -p "Podaj port SSH (domyślnie 22): " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}

    read -p "Podaj port lokalny Ollama (domyślnie 11434): " OLLAMA_PORT
    OLLAMA_PORT=${OLLAMA_PORT:-11434}

    read -p "Podaj port na serwerze OVH (domyślnie 11434): " REMOTE_PORT
    REMOTE_PORT=${REMOTE_PORT:-11434}
fi

echo ""
echo "📝 Konfiguracja:"
echo "   Serwer OVH: $SSH_USER@$OVH_SERVER:$SSH_PORT"
echo "   Port lokalny: $OLLAMA_PORT"
echo "   Port zdalny: $REMOTE_PORT"
echo ""

# Utworzenie systemd service (Linux) lub launchd (MacOS)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    SERVICE_FILE="/etc/systemd/system/ssh-tunnel-ollama.service"
    
    echo "📝 Tworzenie systemd service..."
    sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=SSH Tunnel to OVH Server for Ollama
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/autossh -M 0 -N -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -R $REMOTE_PORT:localhost:$OLLAMA_PORT $SSH_USER@$OVH_SERVER -p $SSH_PORT
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    echo "✅ Utworzono systemd service: $SERVICE_FILE"
    echo ""
    echo "📝 Następne kroki:"
    echo "   1. Skonfiguruj klucz SSH (jeśli jeszcze nie):"
    echo "      ssh-keygen -t ed25519 -C 'ollama-tunnel'"
    echo "      ssh-copy-id $SSH_USER@$OVH_SERVER"
    echo ""
    echo "   2. Przetestuj połączenie:"
    echo "      ssh -R $REMOTE_PORT:localhost:$OLLAMA_PORT $SSH_USER@$OVH_SERVER -N"
    echo ""
    echo "   3. Włącz i uruchom service:"
    echo "      sudo systemctl enable ssh-tunnel-ollama"
    echo "      sudo systemctl start ssh-tunnel-ollama"
    echo ""
    echo "   4. Sprawdź status:"
    echo "      sudo systemctl status ssh-tunnel-ollama"
    echo ""
    echo "   5. Na serwerze OVH, Ollama będzie dostępne na:"
    echo "      http://localhost:$REMOTE_PORT"
    echo "      (lub http://OVH_IP:$REMOTE_PORT jeśli skonfigurowałeś firewall)"
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLIST_FILE="$HOME/Library/LaunchAgents/com.ollama.ssh-tunnel.plist"
    
    echo "📝 Tworzenie launchd plist..."
    cat > $PLIST_FILE <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ollama.ssh-tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/autossh</string>
        <string>-M</string>
        <string>0</string>
        <string>-N</string>
        <string>-o</string>
        <string>ServerAliveInterval 60</string>
        <string>-o</string>
        <string>ServerAliveCountMax 3</string>
        <string>-R</string>
        <string>$REMOTE_PORT:localhost:$OLLAMA_PORT</string>
        <string>$SSH_USER@$OVH_SERVER</string>
        <string>-p</string>
        <string>$SSH_PORT</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/ssh-tunnel-ollama.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/ssh-tunnel-ollama.error.log</string>
</dict>
</plist>
EOF

    echo "✅ Utworzono launchd plist: $PLIST_FILE"
    echo ""
    echo "📝 Następne kroki:"
    echo "   1. Skonfiguruj klucz SSH (jeśli jeszcze nie):"
    echo "      ssh-keygen -t ed25519 -C 'ollama-tunnel'"
    echo "      ssh-copy-id $SSH_USER@$OVH_SERVER"
    echo ""
    echo "   2. Przetestuj połączenie:"
    echo "      ssh -R $REMOTE_PORT:localhost:$OLLAMA_PORT $SSH_USER@$OVH_SERVER -N"
    echo ""
    echo "   3. Załaduj service:"
    echo "      launchctl load $PLIST_FILE"
    echo ""
    echo "   4. Sprawdź status:"
    echo "      launchctl list | grep ssh-tunnel"
    echo ""
    echo "   5. Na serwerze OVH, Ollama będzie dostępne na:"
    echo "      http://localhost:$REMOTE_PORT"
    echo "      (lub http://OVH_IP:$REMOTE_PORT jeśli skonfigurowałeś firewall)"
fi

echo ""
echo "💡 Uwaga: Upewnij się, że na serwerze OVH:"
echo "   - sshd_config ma 'GatewayPorts yes' (dla dostępu z zewnątrz)"
echo "   - Firewall pozwala na port $REMOTE_PORT"
echo "   - Możesz użyć Nginx jako reverse proxy z SSL (zobacz setup-nginx-ovh.sh)"

