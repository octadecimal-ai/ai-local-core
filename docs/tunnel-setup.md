# 🌐 Konfiguracja tunelu dla Ollama

Ten dokument opisuje jak skonfigurować dostęp do Ollama z zewnątrz (z Waldus API) używając tunelu.

## 📋 Dostępne rozwiązania

### 1. Cloudflare Tunnel (Cloudflared) ⭐ - Szybki start

**Zalety:**
- ✅ Darmowe (bez limitów transferu)
- ✅ Bezpieczne (end-to-end encryption)
- ✅ Szybka konfiguracja (15 minut)
- ✅ Nie wymaga rejestracji domeny (można użyć trycloudflare.com)

**Wady:**
- ⚠️ Wymaga rejestracji w Cloudflare (darmowe)
- ⚠️ Dla produkcyjnego użycia wymaga własnej domeny

### 2. Tailscale VPN ⭐⭐ - Najlepsze dla produkcyjnego

**Zalety:**
- ✅ Najbezpieczniejsze (VPN mesh, end-to-end encryption)
- ✅ Darmowe (do 100 urządzeń)
- ✅ Najbardziej niezawodne
- ✅ Bezpośrednie połączenie P2P (bez pośredników)

**Wady:**
- ⚠️ Wymaga instalacji na obu końcach (serwer Ollama + serwer Waldus API)

---

## 🚀 Szybki start - Cloudflare Tunnel

### Krok 1: Instalacja (MacOS)

```bash
# Użyj Homebrew
brew install cloudflared

# Lub użyj skryptu
./scripts/setup-cloudflare-tunnel.sh
```

### Krok 2: Uruchomienie tunelu

```bash
# Szybki start (tryb interaktywny)
cloudflared tunnel --url http://localhost:11434

# Lub użyj skryptu
./scripts/start-tunnel.sh
```

**Wynik:**
```
+--------------------------------------------------------------------------------------------+
|  Your quick Tunnel has been created! Visit it at (it may take some time to be reachable):  |
|  https://xxx-xxx-xxx.trycloudflare.com                                                    |
+--------------------------------------------------------------------------------------------+
```

### Krok 3: Skonfiguruj Waldus API

W pliku `.env` w `waldus-api`:

```env
OLLAMA_URL=https://xxx-xxx-xxx.trycloudflare.com
```

### Krok 4: Test połączenia

```bash
# Z zewnątrz (np. z serwera Waldus API)
curl https://xxx-xxx-xxx.trycloudflare.com/api/tags
```

---

## 🔧 Produkcyjna konfiguracja - Cloudflare Tunnel

### Krok 1: Rejestracja w Cloudflare

1. Zarejestruj się na [cloudflare.com](https://cloudflare.com) (darmowe)
2. Dodaj swoją domenę (lub użyj darmowej domeny Cloudflare)
3. Skonfiguruj DNS

### Krok 2: Logowanie do Cloudflare

```bash
cloudflared tunnel login
```

### Krok 3: Utworzenie tunelu

```bash
# Utwórz tunnel
cloudflared tunnel create ollama-tunnel

# Skonfiguruj tunnel
./scripts/setup-cloudflare-tunnel-service.sh
```

### Krok 4: Konfiguracja DNS

W Cloudflare Dashboard:
1. Przejdź do DNS → Records
2. Dodaj CNAME record:
   - **Name:** `ollama` (lub subdomena)
   - **Target:** `<tunnel-id>.cfargotunnel.com`
   - **Proxy:** Enabled (pomarańczowa chmura)

### Krok 5: Konfiguracja jako systemd service (Ubuntu Server)

```bash
# Edytuj konfigurację
sudo nano /etc/cloudflared/config.yml

# Włącz i uruchom service
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

# Sprawdź status
sudo systemctl status cloudflared
```

---

## 🔐 Konfiguracja Tailscale VPN

### Krok 1: Instalacja na serwerze Ollama

```bash
# MacOS
brew install tailscale

# Linux
curl -fsSL https://tailscale.com/install.sh | sh

# Lub użyj skryptu
./scripts/setup-tailscale.sh
```

### Krok 2: Połączenie z Tailscale

```bash
# MacOS
tailscale up

# Linux
sudo tailscale up
```

**Wynik:**
- Otworzy się przeglądarka z logowaniem
- Po zalogowaniu otrzymasz Tailscale IP (np. `100.x.x.x`)

### Krok 3: Instalacja na serwerze Waldus API

```bash
# Powtórz kroki 1-2 na serwerze Waldus API
```

### Krok 4: Sprawdzenie połączenia

```bash
# Na serwerze Ollama - sprawdź IP
tailscale ip -4

# Na serwerze Waldus API - sprawdź czy widzisz serwer Ollama
tailscale status
```

### Krok 5: Konfiguracja Ollama do nasłuchiwania na Tailscale

```bash
# Uruchom Ollama z nasłuchiwaniem na wszystkich interfejsach
OLLAMA_HOST=0.0.0.0 ollama serve

# Lub edytuj systemd service
sudo systemctl edit ollama
```

Dodaj do konfiguracji:
```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
```

### Krok 6: Skonfiguruj Waldus API

W pliku `.env` w `waldus-api`:

```env
OLLAMA_URL=http://100.x.x.x:11434
```

(Gdzie `100.x.x.x` to Tailscale IP serwera z Ollama)

### Krok 7: Test połączenia

```bash
# Z serwera Waldus API
curl http://100.x.x.x:11434/api/tags
```

---

## 🔒 Bezpieczeństwo

### Problem: Ollama domyślnie nie ma autoryzacji

**Rozwiązanie: Nginx Reverse Proxy z Basic Auth**

#### Instalacja Nginx (Ubuntu Server)

```bash
sudo apt update
sudo apt install nginx apache2-utils
```

#### Konfiguracja Basic Auth

```bash
# Utwórz plik z hasłem
sudo htpasswd -c /etc/nginx/.htpasswd ollama-user
```

#### Konfiguracja Nginx

```bash
sudo nano /etc/nginx/sites-available/ollama
```

Dodaj konfigurację:

```nginx
server {
    listen 11435;
    server_name localhost;

    location / {
        auth_basic "Ollama API";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        proxy_pass http://localhost:11434;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout dla długich requestów
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
```

#### Włącz konfigurację

```bash
sudo ln -s /etc/nginx/sites-available/ollama /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### Aktualizacja tunelu

Zamiast `http://localhost:11434`, użyj `http://localhost:11435` w konfiguracji tunelu.

#### Aktualizacja Waldus API

W pliku `.env`:

```env
OLLAMA_URL=https://xxx.trycloudflare.com
OLLAMA_USER=ollama-user
OLLAMA_PASSWORD=twoje-haslo
```

---

## 📊 Porównanie rozwiązań

| Aspekt | Cloudflare Tunnel | Tailscale |
|--------|-------------------|-----------|
| **Konfiguracja** | Średnia (15-30 min) | Prosta (10 min) |
| **Bezpieczeństwo** | Wysokie | Najwyższe (VPN) |
| **Koszt** | Darmowe | Darmowe |
| **Niezawodność** | Wysoka | Najwyższa |
| **Wydajność** | Dobra | Najlepsza (P2P) |
| **Wymagania** | Konto Cloudflare | Instalacja na obu końcach |
| **Dla development** | ✅ Idealne | ⚠️ Wymaga instalacji |
| **Dla production** | ✅ Dobre | ✅ Najlepsze |

---

## 🎯 Rekomendacje

### Development (MacOS)
- **Cloudflare Tunnel** - szybki start, nie wymaga instalacji na obu końcach

### Production (Ubuntu Server)
- **Tailscale** - najlepsze bezpieczeństwo i wydajność
- **Cloudflare Tunnel** - jeśli nie możesz zainstalować Tailscale na serwerze Waldus API

---

## 🐛 Rozwiązywanie problemów

### Cloudflare Tunnel nie działa

```bash
# Sprawdź czy tunnel działa
cloudflared tunnel list

# Sprawdź logi
journalctl -u cloudflared -f
```

### Tailscale nie widzi serwera

```bash
# Sprawdź status
tailscale status

# Sprawdź ping
ping 100.x.x.x

# Restart Tailscale
sudo systemctl restart tailscale
```

### Ollama nie odpowiada przez tunnel

```bash
# Sprawdź czy Ollama działa lokalnie
curl http://localhost:11434/api/tags

# Sprawdź logi Ollama
journalctl -u ollama -f
```

---

## 📚 Źródła

- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Tailscale Docs](https://tailscale.com/kb/)
- [Ollama API Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)

