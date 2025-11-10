#!/bin/bash
# Skrypt testowy do ręcznego uruchomienia SSH Tunnel
# Użyj tego do testowania przed skonfigurowaniem automatycznego uruchamiania

set -e

echo "🔐 Test SSH Tunnel do serwera OVH"
echo "=================================="
echo ""

# Pobierz dane od użytkownika
read -p "Podaj adres serwera OVH (np. server.example.com lub IP): " OVH_SERVER
read -p "Podaj użytkownika SSH (np. root): " SSH_USER
read -p "Podaj port SSH (domyślnie 22): " SSH_PORT
SSH_PORT=${SSH_PORT:-22}

read -p "Podaj port lokalny Ollama (domyślnie 11434): " OLLAMA_PORT
OLLAMA_PORT=${OLLAMA_PORT:-11434}

read -p "Podaj port na serwerze OVH (domyślnie 11434): " REMOTE_PORT
REMOTE_PORT=${REMOTE_PORT:-11434}

echo ""
echo "📝 Konfiguracja:"
echo "   Serwer OVH: $SSH_USER@$OVH_SERVER:$SSH_PORT"
echo "   Port lokalny: $OLLAMA_PORT"
echo "   Port zdalny: $REMOTE_PORT"
echo ""

# Sprawdź czy Ollama działa lokalnie
if ! curl -s http://localhost:$OLLAMA_PORT/api/tags > /dev/null 2>&1; then
    echo "⚠️  Uwaga: Ollama nie odpowiada na localhost:$OLLAMA_PORT"
    echo "   Upewnij się, że Ollama działa: ollama serve"
    echo ""
    read -p "Kontynuować mimo to? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        exit 1
    fi
fi

echo "🔑 Sprawdzanie klucza SSH..."
if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
    echo "⚠️  Nie znaleziono klucza SSH"
    echo ""
    read -p "Czy chcesz wygenerować nowy klucz SSH? (y/n): " GEN_KEY
    if [ "$GEN_KEY" = "y" ]; then
        ssh-keygen -t ed25519 -C "ollama-tunnel" -f ~/.ssh/id_ed25519_ollama
        echo ""
        echo "📋 Skopiuj klucz na serwer OVH:"
        echo "   ssh-copy-id -i ~/.ssh/id_ed25519_ollama.pub $SSH_USER@$OVH_SERVER"
        echo ""
        read -p "Naciśnij Enter po skopiowaniu klucza..."
        SSH_KEY="-i ~/.ssh/id_ed25519_ollama"
    else
        SSH_KEY=""
    fi
else
    SSH_KEY=""
fi

echo ""
echo "🚀 Uruchamianie SSH Tunnel..."
echo "   Naciśnij Ctrl+C aby zatrzymać"
echo ""
echo "💡 W osobnym terminalu możesz przetestować:"
echo "   curl http://$OVH_SERVER:$REMOTE_PORT/api/tags"
echo ""

# Uruchom SSH tunnel
ssh $SSH_KEY -R $REMOTE_PORT:localhost:$OLLAMA_PORT $SSH_USER@$OVH_SERVER -p $SSH_PORT -N -v

