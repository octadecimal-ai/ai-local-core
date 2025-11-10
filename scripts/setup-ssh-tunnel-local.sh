#!/bin/bash
# Skrypt do konfiguracji SSH Tunnel z lokalnym port forwarding
# Alternatywa gdy remote port forwarding nie działa
# Uruchamia SSH na serwerze OVH, który forwarduje do lokalnego Ollama

set -e

echo "🔐 Konfiguracja SSH Tunnel (Local Port Forwarding)"
echo "==================================================="
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
    OVH_SERVER=$1
    SSH_USER=${2:-$(whoami)}
    SSH_PORT=${3:-22}
    OLLAMA_PORT=${4:-11434}
    REMOTE_PORT=${5:-11435}
    echo "📝 Używam parametrów z linii poleceń:"
    echo "   Serwer: $OVH_SERVER"
    echo "   Użytkownik: $SSH_USER"
    echo "   Port SSH: $SSH_PORT"
    echo "   Port lokalny Ollama: $OLLAMA_PORT"
    echo "   Port na serwerze OVH: $REMOTE_PORT"
    echo ""
else
    read -p "Podaj adres serwera OVH (np. server.example.com lub IP): " OVH_SERVER
    read -p "Podaj użytkownika SSH (domyślnie $(whoami)): " SSH_USER
    SSH_USER=${SSH_USER:-$(whoami)}
    read -p "Podaj port SSH (domyślnie 22): " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}

    read -p "Podaj port lokalny Ollama (domyślnie 11434): " OLLAMA_PORT
    OLLAMA_PORT=${OLLAMA_PORT:-11434}

    read -p "Podaj port na serwerze OVH (domyślnie 11435): " REMOTE_PORT
    REMOTE_PORT=${REMOTE_PORT:-11435}
fi

echo ""
echo "📝 Konfiguracja:"
echo "   Serwer OVH: $SSH_USER@$OVH_SERVER:$SSH_PORT"
echo "   Port lokalny Ollama: $OLLAMA_PORT"
echo "   Port na serwerze OVH: $REMOTE_PORT"
echo ""
echo "💡 To rozwiązanie używa lokalnego port forwarding"
echo "   Na serwerze OVH uruchom: ssh -L $REMOTE_PORT:localhost:$OLLAMA_PORT $SSH_USER@$OVH_SERVER -N"
echo "   (lub użyj skryptu na serwerze)"
echo ""

# Utworzenie skryptu do uruchomienia na serwerze OVH
SERVER_SCRIPT="/tmp/setup-ollama-tunnel-server.sh"
cat > $SERVER_SCRIPT <<'EOFSCRIPT'
#!/bin/bash
# Skrypt do uruchomienia na serwerze OVH
# Forwarduje port z serwera do lokalnego Ollama przez SSH

OVH_SERVER="waldus-server"
SSH_USER="waldusz"
SSH_PORT=22
OLLAMA_PORT=11434
REMOTE_PORT=11435

echo "🔐 Uruchamianie SSH Tunnel na serwerze OVH"
echo "=========================================="
echo ""
echo "📝 Konfiguracja:"
echo "   Forwardowanie: localhost:$REMOTE_PORT -> $SSH_USER@$OVH_SERVER (localhost:$OLLAMA_PORT)"
echo ""
echo "💡 To połączenie będzie działać dopóki sesja SSH jest aktywna"
echo "   Użyj screen/tmux lub systemd service dla trwałego połączenia"
echo ""

# Uruchom SSH tunnel
ssh -L $REMOTE_PORT:localhost:$OLLAMA_PORT $SSH_USER@$OVH_SERVER -p $SSH_PORT -N -v
EOFSCRIPT

echo "✅ Utworzono skrypt dla serwera OVH: $SERVER_SCRIPT"
echo ""
echo "📋 INSTRUKCJA:"
echo ""
echo "1. Skopiuj skrypt na serwer OVH:"
echo "   scp $SERVER_SCRIPT $SSH_USER@$OVH_SERVER:/tmp/"
echo ""
echo "2. Zaloguj się na serwer OVH i uruchom:"
echo "   ssh $SSH_USER@$OVH_SERVER"
echo "   chmod +x /tmp/setup-ollama-tunnel-server.sh"
echo "   /tmp/setup-ollama-tunnel-server.sh"
echo ""
echo "3. Alternatywnie, użyj screen/tmux dla trwałego połączenia:"
echo "   screen -S ollama-tunnel"
echo "   ssh -L $REMOTE_PORT:localhost:$OLLAMA_PORT $SSH_USER@$OVH_SERVER -N"
echo "   (Ctrl+A, D aby odłączyć screen)"
echo ""
echo "4. Na serwerze OVH, Ollama będzie dostępne na:"
echo "   http://localhost:$REMOTE_PORT"
echo ""
echo "5. Z zewnątrz (jeśli skonfigurowałeś Nginx):"
echo "   http://OVH_IP:$REMOTE_PORT"
echo ""

