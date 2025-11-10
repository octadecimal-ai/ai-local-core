#!/bin/bash
# Skrypt do konfiguracji Tailscale VPN dla Ollama
# Działa na MacOS i Linux

set -e

echo "🔐 Konfiguracja Tailscale VPN dla Ollama"
echo "========================================"
echo ""

# Sprawdź system operacyjny
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo "❌ Nieobsługiwany system operacyjny: $OSTYPE"
    exit 1
fi

echo "📦 System: $OS"
echo ""

# Sprawdź czy Tailscale jest już zainstalowany
if command -v tailscale &> /dev/null; then
    echo "✅ Tailscale jest już zainstalowany"
    tailscale version
    echo ""
    
    # Sprawdź status
    if tailscale status &> /dev/null; then
        echo "📡 Status Tailscale:"
        tailscale status
        echo ""
        echo "✅ Tailscale jest połączony!"
        echo ""
        echo "📍 Twój Tailscale IP:"
        tailscale ip -4
        echo ""
        echo "💡 Użyj tego IP w konfiguracji Waldus API:"
        echo "   http://$(tailscale ip -4):11434"
    else
        echo "⚠️  Tailscale nie jest połączony"
        echo ""
        echo "🔗 Aby połączyć się z Tailscale, uruchom:"
        echo "   sudo tailscale up"
    fi
else
    echo "📥 Instalowanie Tailscale..."
    
    if [ "$OS" == "macos" ]; then
        # MacOS - użyj Homebrew
        if command -v brew &> /dev/null; then
            brew install tailscale
        else
            echo "❌ Homebrew nie jest zainstalowany. Zainstaluj: https://brew.sh"
            exit 1
        fi
    else
        # Linux - użyj oficjalnego skryptu
        curl -fsSL https://tailscale.com/install.sh | sh
    fi
    
    echo ""
    echo "✅ Tailscale zainstalowany!"
    echo ""
    echo "🔗 Aby połączyć się z Tailscale, uruchom:"
    if [ "$OS" == "macos" ]; then
        echo "   tailscale up"
    else
        echo "   sudo tailscale up"
    fi
    echo ""
    echo "📝 Po połączeniu otrzymasz Tailscale IP, które możesz użyć w konfiguracji"
fi

echo ""
echo "📋 Instrukcje konfiguracji:"
echo "   1. Zainstaluj Tailscale na serwerze z Ollama (ten skrypt)"
echo "   2. Zainstaluj Tailscale na serwerze Waldus API"
echo "   3. Oba serwery będą widoczne w sieci Tailscale"
echo "   4. Użyj Tailscale IP serwera z Ollama w konfiguracji Waldus API"
echo "   5. Przykład: http://100.x.x.x:11434"
echo ""

