#!/bin/bash
# Skrypt do uruchomienia tunelu (Cloudflare lub Tailscale)
# Używa zmiennej środowiskowej TUNNEL_TYPE

set -e

TUNNEL_TYPE=${TUNNEL_TYPE:-"cloudflare"}

echo "🚀 Uruchamianie tunelu: $TUNNEL_TYPE"
echo "===================================="
echo ""

case $TUNNEL_TYPE in
    cloudflare)
        if ! command -v cloudflared &> /dev/null; then
            echo "❌ cloudflared nie jest zainstalowany"
            echo "   Uruchom: ./scripts/setup-cloudflare-tunnel.sh"
            exit 1
        fi
        
        echo "🌐 Uruchamianie Cloudflare Tunnel..."
        echo "   URL będzie wyświetlony poniżej"
        echo ""
        cloudflared tunnel --url http://localhost:11434
        ;;
    
    tailscale)
        if ! command -v tailscale &> /dev/null; then
            echo "❌ Tailscale nie jest zainstalowany"
            echo "   Uruchom: ./scripts/setup-tailscale.sh"
            exit 1
        fi
        
        echo "🔐 Sprawdzanie statusu Tailscale..."
        if tailscale status &> /dev/null; then
            TAILSCALE_IP=$(tailscale ip -4)
            echo "✅ Tailscale jest połączony!"
            echo ""
            echo "📍 Twój Tailscale IP: $TAILSCALE_IP"
            echo "💡 URL Ollama: http://$TAILSCALE_IP:11434"
            echo ""
            echo "⚠️  Upewnij się, że Ollama nasłuchuje na wszystkich interfejsach:"
            echo "   OLLAMA_HOST=0.0.0.0 ollama serve"
            echo ""
        else
            echo "❌ Tailscale nie jest połączony"
            echo "   Uruchom: sudo tailscale up"
            exit 1
        fi
        ;;
    
    *)
        echo "❌ Nieznany typ tunelu: $TUNNEL_TYPE"
        echo "   Dostępne opcje: cloudflare, tailscale"
        exit 1
        ;;
esac

