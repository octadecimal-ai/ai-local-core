#!/bin/bash
# Skrypt do konfiguracji Nginx Reverse Proxy na serwerze OVH
# Użyj tego po skonfigurowaniu SSH Tunnel lub WireGuard

set -e

echo "🌐 Konfiguracja Nginx Reverse Proxy na serwerze OVH"
echo "==================================================="
echo ""

echo "⚠️  Uwaga: Ten skrypt należy uruchomić NA SERWERZE OVH"
echo ""

# Sprawdź czy jesteś root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Uruchom skrypt jako root (sudo)"
    exit 1
fi

# Instalacja Nginx i certbot
if ! command -v nginx &> /dev/null; then
    echo "📥 Instalowanie Nginx..."
    apt update
    apt install -y nginx certbot python3-certbot-nginx
fi

echo "✅ Nginx zainstalowany"
echo ""

# Pobierz dane od użytkownika
read -p "Podaj domenę (np. ollama.example.com): " DOMAIN
read -p "Podaj port lokalny Ollama (domyślnie 11434): " OLLAMA_PORT
OLLAMA_PORT=${OLLAMA_PORT:-11434}

read -p "Czy chcesz dodać Basic Auth? (y/n): " USE_AUTH
USE_AUTH=${USE_AUTH:-n}

# Konfiguracja Basic Auth
if [ "$USE_AUTH" = "y" ]; then
    apt install -y apache2-utils
    read -p "Podaj nazwę użytkownika: " AUTH_USER
    htpasswd -c /etc/nginx/.htpasswd $AUTH_USER
    AUTH_CONFIG="
        auth_basic \"Ollama API\";
        auth_basic_user_file /etc/nginx/.htpasswd;"
else
    AUTH_CONFIG=""
fi

# Utworzenie konfiguracji Nginx
NGINX_CONFIG="/etc/nginx/sites-available/ollama"
cat > $NGINX_CONFIG <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    # Redirect to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    # SSL certificates (będą skonfigurowane przez certbot)
    # ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Logs
    access_log /var/log/nginx/ollama-access.log;
    error_log /var/log/nginx/ollama-error.log;

    # Proxy settings
    location / {
        $AUTH_CONFIG
        
        proxy_pass http://localhost:$OLLAMA_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeout dla długich requestów (LLM może generować długo)
        proxy_read_timeout 600s;
        proxy_connect_timeout 75s;
        proxy_send_timeout 600s;
        
        # WebSocket support (jeśli potrzebne)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

echo "✅ Utworzono konfigurację Nginx: $NGINX_CONFIG"
echo ""

# Włącz konfigurację
ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/
nginx -t

echo ""
echo "📝 Następne kroki:"
echo ""
echo "1. Skonfiguruj DNS:"
echo "   Dodaj A record dla $DOMAIN wskazujący na IP serwera OVH"
echo ""
echo "2. Uzyskaj certyfikat SSL:"
echo "   certbot --nginx -d $DOMAIN"
echo ""
echo "3. Przeładuj Nginx:"
echo "   systemctl reload nginx"
echo ""
echo "4. Sprawdź status:"
echo "   systemctl status nginx"
echo ""
echo "5. Test połączenia:"
echo "   curl https://$DOMAIN/api/tags"
echo ""
echo "✅ Ollama będzie dostępne na: https://$DOMAIN"
echo ""
echo "💡 Konfiguracja w Waldus API (.env):"
echo "   OLLAMA_URL=https://$DOMAIN"
if [ "$USE_AUTH" = "y" ]; then
    echo "   OLLAMA_USER=$AUTH_USER"
    echo "   OLLAMA_PASSWORD=<hasło które podałeś>"
fi

