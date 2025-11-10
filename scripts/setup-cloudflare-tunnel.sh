#!/bin/bash
# Skrypt do konfiguracji Cloudflare Tunnel dla Ollama
# Działa na MacOS i Linux

set -e

echo "🌐 Konfiguracja Cloudflare Tunnel dla Ollama"
echo "============================================"
echo ""

# Sprawdź system operacyjny
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    ARCH="darwin-amd64"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    ARCH="linux-amd64"
else
    echo "❌ Nieobsługiwany system operacyjny: $OSTYPE"
    exit 1
fi

echo "📦 System: $OS"
echo ""

# Sprawdź czy cloudflared jest już zainstalowany
if command -v cloudflared &> /dev/null; then
    echo "✅ cloudflared jest już zainstalowany"
    cloudflared --version
else
    echo "📥 Instalowanie cloudflared..."
    
    if [ "$OS" == "macos" ]; then
        # MacOS - użyj Homebrew
        if command -v brew &> /dev/null; then
            brew install cloudflared
        else
            echo "❌ Homebrew nie jest zainstalowany. Zainstaluj: https://brew.sh"
            exit 1
        fi
    else
        # Linux - pobierz binarkę
        cd /tmp
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-${ARCH}
        chmod +x cloudflared-${ARCH}
        sudo mv cloudflared-${ARCH} /usr/local/bin/cloudflared
        echo "✅ cloudflared zainstalowany w /usr/local/bin/cloudflared"
    fi
fi

echo ""
echo "🚀 Uruchamianie tunelu..."
echo ""
echo "📝 Instrukcje:"
echo "   1. Tunnel zostanie uruchomiony w trybie interaktywnym"
echo "   2. Skopiuj wygenerowany URL (np. https://xxx.trycloudflare.com)"
echo "   3. Użyj tego URL w konfiguracji Waldus API"
echo "   4. Naciśnij Ctrl+C aby zatrzymać tunel"
echo ""
echo "⚠️  Uwaga: Dla produkcyjnego użycia skonfiguruj tunnel jako systemd service"
echo ""

# Uruchom tunnel
cloudflared tunnel --url http://localhost:11434

