# 🖥️ Konfiguracja tunelu z serwerem OVH

Ten dokument opisuje jak skonfigurować własny tunel używając serwera OVH jako pośrednika. To rozwiązanie daje pełną kontrolę nad infrastrukturą i nie wymaga zewnętrznych usług.

## 📋 Dostępne rozwiązania

### 1. SSH Tunnel ⭐ - Najprostsze

**Zalety:**
- ✅ Używa istniejącego serwera OVH
- ✅ Nie wymaga dodatkowej konfiguracji na serwerze
- ✅ Szybka konfiguracja (10 minut)
- ✅ Automatyczne reconnect (autossh)

**Wady:**
- ⚠️ Wymaga otwartego portu SSH na serwerze
- ⚠️ Mniej wydajne niż WireGuard

**Kiedy użyć:**
- Szybki start
- Tymczasowe rozwiązanie
- Gdy nie chcesz konfigurować VPN

### 2. WireGuard VPN ⭐⭐ - Najlepsze

**Zalety:**
- ✅ Najszybsze (niski overhead)
- ✅ Najbezpieczniejsze (nowoczesna kryptografia)
- ✅ Pełna kontrola
- ✅ Możliwość rozszerzenia na więcej urządzeń

**Wady:**
- ⚠️ Wymaga konfiguracji na serwerze
- ⚠️ Wymaga konfiguracji firewall

**Kiedy użyć:**
- Produkcyjne użycie
- Gdy potrzebujesz najlepszej wydajności
- Gdy planujesz rozszerzyć na więcej urządzeń

### 3. Nginx Reverse Proxy (z SSL) ⭐⭐⭐ - Kompletne rozwiązanie

**Zalety:**
- ✅ Własna domena z SSL (Let's Encrypt)
- ✅ Basic Auth dla bezpieczeństwa
- ✅ Profesjonalne rozwiązanie
- ✅ Możliwość dodania rate limiting

**Wady:**
- ⚠️ Wymaga własnej domeny
- ⚠️ Wymaga konfiguracji DNS

**Kiedy użyć:**
- Produkcyjne użycie
- Gdy masz własną domenę
- Gdy potrzebujesz profesjonalnego rozwiązania

---

## 🚀 Rozwiązanie 1: SSH Tunnel (Szybki start)

### Architektura

```
[Lokalny PC z Ollama] --SSH Tunnel--> [Serwer OVH] --Publiczny IP--> [Waldus API]
```

### Krok 1: Instalacja autossh (lokalnie)

```bash
# MacOS
brew install autossh

# Linux
sudo apt install autossh

# Lub użyj skryptu
./scripts/setup-ssh-tunnel.sh
```

### Krok 2: Konfiguracja klucza SSH

```bash
# Wygeneruj klucz SSH (jeśli jeszcze nie masz)
ssh-keygen -t ed25519 -C "ollama-tunnel"

# Skopiuj klucz na serwer OVH
ssh-copy-id user@ovh-server.com
```

### Krok 3: Konfiguracja tunelu

```bash
# Uruchom skrypt konfiguracyjny
./scripts/setup-ssh-tunnel.sh
```

Skrypt zapyta o:
- Adres serwera OVH
- Użytkownika SSH
- Port SSH
- Port lokalny Ollama
- Port na serwerze OVH

### Krok 4: Konfiguracja serwera OVH

Na serwerze OVH edytuj `/etc/ssh/sshd_config`:

```bash
sudo nano /etc/ssh/sshd_config
```

Dodaj/zmień:
```
GatewayPorts yes
AllowTcpForwarding yes
```

Przeładuj SSH:
```bash
sudo systemctl reload sshd
```

### Krok 5: Test połączenia

```bash
# Ręczny test
ssh -R 11434:localhost:11434 user@ovh-server.com -N

# W osobnym terminalu sprawdź
curl http://ovh-server-ip:11434/api/tags
```

### Krok 6: Automatyczne uruchomienie

**MacOS:**
```bash
# Skrypt utworzy launchd plist
launchctl load ~/Library/LaunchAgents/com.ollama.ssh-tunnel.plist
```

**Linux:**
```bash
# Skrypt utworzy systemd service
sudo systemctl enable ssh-tunnel-ollama
sudo systemctl start ssh-tunnel-ollama
```

### Krok 7: Konfiguracja w Waldus API

W pliku `.env` w `waldus-api`:

```env
OLLAMA_URL=http://ovh-server-ip:11434
```

---

## 🔐 Rozwiązanie 2: WireGuard VPN

### Architektura

```
[Lokalny PC] <--WireGuard VPN--> [Serwer OVH] <--Publiczny IP--> [Waldus API]
```

### Krok 1: Instalacja WireGuard (lokalnie)

```bash
# MacOS
brew install wireguard-tools

# Linux
sudo apt install wireguard wireguard-tools

# Lub użyj skryptu
./scripts/setup-wireguard-ovh.sh
```

### Krok 2: Konfiguracja serwera OVH

Zaloguj się na serwer OVH:

```bash
ssh user@ovh-server.com
```

Zainstaluj WireGuard:
```bash
sudo apt update
sudo apt install -y wireguard wireguard-tools
```

Włącz IP forwarding:
```bash
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

Wygeneruj klucze:
```bash
sudo wg genkey | sudo tee /etc/wireguard/private.key | sudo wg pubkey | sudo tee /etc/wireguard/public.key
```

### Krok 3: Konfiguracja lokalna

```bash
# Uruchom skrypt konfiguracyjny
./scripts/setup-wireguard-ovh.sh
```

Skrypt wygeneruje:
- Klucze lokalne
- Konfigurację lokalną (`~/.wireguard/wg0.conf`)
- Konfigurację serwera (do skopiowania)

### Krok 4: Konfiguracja serwera OVH

Skopiuj konfigurację serwera:
```bash
scp /tmp/wg0-server.conf user@ovh-server.com:/tmp/
```

Na serwerze OVH:
```bash
# Edytuj konfigurację
sudo nano /etc/wireguard/wg0.conf

# Wklej klucz prywatny serwera (z /etc/wireguard/private.key)
# Skopiuj konfigurację z /tmp/wg0-server.conf

# Włącz i uruchom
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

### Krok 5: Konfiguracja firewall (serwer OVH)

```bash
# Otwórz port WireGuard
sudo ufw allow 51820/udp

# Otwórz port Ollama (jeśli potrzebny z zewnątrz)
sudo ufw allow 11434/tcp
```

### Krok 6: Uruchomienie lokalnie

**MacOS:**
```bash
sudo wg-quick up ~/.wireguard/wg0.conf
```

**Linux:**
```bash
sudo wg-quick up wg0
```

### Krok 7: Test połączenia

```bash
# Ping serwera przez VPN
ping 10.0.0.1  # (lub IP z konfiguracji)

# Test Ollama
curl http://10.0.0.1:11434/api/tags
```

### Krok 8: Konfiguracja w Waldus API

W pliku `.env` w `waldus-api`:

```env
OLLAMA_URL=http://ovh-server-wg-ip:11434
```

---

## 🌐 Rozwiązanie 3: Nginx Reverse Proxy z SSL

### Architektura

```
[Waldus API] --HTTPS--> [Nginx na OVH] --HTTP--> [Ollama przez SSH/WireGuard]
```

### Krok 1: Konfiguracja DNS

W panelu DNS dodaj A record:
- **Name:** `ollama` (lub subdomena)
- **Type:** A
- **Value:** IP serwera OVH
- **TTL:** 3600

### Krok 2: Konfiguracja Nginx na serwerze OVH

Zaloguj się na serwer OVH i uruchom:

```bash
# Użyj skryptu konfiguracyjnego
./scripts/setup-nginx-ovh.sh
```

Skrypt zapyta o:
- Domenę
- Port lokalny Ollama
- Czy dodać Basic Auth

### Krok 3: Uzyskanie certyfikatu SSL

```bash
# Na serwerze OVH
sudo certbot --nginx -d ollama.example.com
```

### Krok 4: Test połączenia

```bash
curl https://ollama.example.com/api/tags
```

### Krok 5: Konfiguracja w Waldus API

W pliku `.env` w `waldus-api`:

```env
OLLAMA_URL=https://ollama.example.com
OLLAMA_USER=ollama-user  # jeśli Basic Auth
OLLAMA_PASSWORD=haslo     # jeśli Basic Auth
```

---

## 📊 Porównanie rozwiązań

| Aspekt | SSH Tunnel | WireGuard | Nginx + SSL |
|--------|-----------|-----------|-------------|
| **Konfiguracja** | Prosta (10 min) | Średnia (30 min) | Średnia (30 min) |
| **Wydajność** | Dobra | Najlepsza | Dobra |
| **Bezpieczeństwo** | Wysokie | Najwyższe | Najwyższe + SSL |
| **Koszt** | Darmowe | Darmowe | Darmowe (Let's Encrypt) |
| **Własna domena** | Nie | Nie | Tak |
| **SSL** | Nie | Nie | Tak |
| **Dla production** | ⚠️ Tymczasowe | ✅ Tak | ✅ Tak |

---

## 🎯 Rekomendacje

### Development / Testy
- **SSH Tunnel** - najszybsze do uruchomienia

### Production
- **WireGuard + Nginx + SSL** - najlepsze rozwiązanie
- **SSH Tunnel + Nginx + SSL** - jeśli nie chcesz konfigurować VPN

---

## 🔒 Bezpieczeństwo

### SSH Tunnel
- Użyj kluczy SSH (nie hasła)
- Wyłącz logowanie hasłem w `sshd_config`
- Użyj niestandardowego portu SSH

### WireGuard
- Regularnie aktualizuj klucze
- Użyj silnych kluczy (wg genkey)
- Skonfiguruj firewall

### Nginx
- Użyj Basic Auth
- Skonfiguruj rate limiting
- Użyj SSL (Let's Encrypt)
- Regularnie aktualizuj certyfikaty

---

## 🐛 Rozwiązywanie problemów

### SSH Tunnel nie działa

```bash
# Sprawdź czy tunnel działa
ps aux | grep autossh

# Sprawdź logi
tail -f /tmp/ssh-tunnel-ollama.log

# Test ręczny
ssh -R 11434:localhost:11434 user@ovh-server.com -v
```

### WireGuard nie łączy się

```bash
# Sprawdź status
sudo wg show

# Sprawdź logi
sudo journalctl -u wg-quick@wg0 -f

# Test ping
ping 10.0.0.1
```

### Nginx nie działa

```bash
# Sprawdź konfigurację
sudo nginx -t

# Sprawdź logi
sudo tail -f /var/log/nginx/ollama-error.log

# Sprawdź status
sudo systemctl status nginx
```

---

## 📚 Źródła

- [WireGuard Documentation](https://www.wireguard.com/)
- [Nginx Reverse Proxy](https://nginx.org/en/docs/http/ngx_http_proxy_module.html)
- [Let's Encrypt](https://letsencrypt.org/)
- [SSH Tunnel Guide](https://www.ssh.com/academy/ssh/tunneling)

