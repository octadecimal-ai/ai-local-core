# 🤖 Integracja bota (Waldus API) z WireGuard VPN

Po skonfigurowaniu WireGuard VPN, musisz podłączyć bota (Waldus API) do Ollama przez VPN.

## 📋 Wymagania

- ✅ WireGuard VPN skonfigurowany i działający
- ✅ Ollama dostępne przez VPN na `http://10.0.0.1:11434` (lub IP serwera z konfiguracji)
- ✅ Waldus API ma dostęp do serwera OVH (gdzie działa WireGuard)

## 🔧 Opcja 1: Waldus API na serwerze OVH (Najprostsze)

Jeśli Waldus API działa na tym samym serwerze OVH co WireGuard:

### Konfiguracja

W pliku `.env` w `waldus-api`:

```env
# Ollama przez WireGuard VPN
OLLAMA_URL=http://10.0.0.1:11434
```

**Uwaga:** `10.0.0.1` to WireGuard IP serwera. Jeśli użyłeś innego IP, zmień adres.

### Test połączenia

Na serwerze OVH:

```bash
curl http://10.0.0.1:11434/api/tags
```

---

## 🔧 Opcja 2: Waldus API na innym serwerze (z WireGuard)

Jeśli Waldus API działa na innym serwerze, musisz zainstalować WireGuard również tam.

### Krok 1: Zainstaluj WireGuard na serwerze Waldus API

```bash
# Na serwerze Waldus API
apt update
apt install -y wireguard wireguard-tools
```

### Krok 2: Skonfiguruj WireGuard na serwerze Waldus API

Użyj tego samego klucza publicznego serwera OVH i dodaj nowy peer w konfiguracji serwera OVH.

**Na serwerze OVH** - edytuj `/etc/wireguard/wg0.conf`:

```ini
[Peer]
PublicKey = <PUBLIC_KEY_SERVER_WALDUS_API>
AllowedIPs = 10.0.0.3/32  # Nowy IP dla serwera Waldus API
```

**Na serwerze Waldus API** - utwórz `/etc/wireguard/wg0.conf`:

```ini
[Interface]
PrivateKey = <PRIVATE_KEY_WALDUS_API>
Address = 10.0.0.3/24
DNS = 1.1.1.1

[Peer]
PublicKey = <PUBLIC_KEY_SERVER_OVH>
Endpoint = waldus-server:51820
AllowedIPs = 10.0.0.1/32
PersistentKeepalive = 25
```

### Krok 3: Uruchom WireGuard na serwerze Waldus API

```bash
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
```

### Krok 4: Konfiguracja w Waldus API

W pliku `.env` w `waldus-api`:

```env
OLLAMA_URL=http://10.0.0.1:11434
```

---

## 🔧 Opcja 3: Waldus API lokalnie (MacOS) z WireGuard

Jeśli Waldus API działa lokalnie na MacOS (gdzie masz Ollama):

### Konfiguracja

W pliku `.env` w `waldus-api`:

```env
# Ollama lokalnie (ten sam komputer)
OLLAMA_URL=http://localhost:11434
```

**Uwaga:** Jeśli Waldus API i Ollama są na tym samym komputerze, nie potrzebujesz VPN - użyj `localhost`.

---

## 🧪 Testowanie połączenia

### Test 1: Z serwera OVH

```bash
# Sprawdź czy WireGuard działa
wg show

# Test połączenia do Ollama przez VPN
curl http://10.0.0.1:11434/api/tags
```

### Test 2: Z lokalnego PC (MacOS)

```bash
# Sprawdź status WireGuard
wg show

# Test ping do serwera
ping 10.0.0.1

# Test połączenia do Ollama
curl http://10.0.0.1:11434/api/tags
```

### Test 3: Z Waldus API

W terminalu na serwerze Waldus API:

```bash
# Test bezpośredni
curl http://10.0.0.1:11434/api/tags

# Test przez PHP (jeśli masz dostęp)
php -r "echo file_get_contents('http://10.0.0.1:11434/api/tags');"
```

---

## 📝 Aktualizacja OllamaProvider w Waldus API

Jeśli używasz `OllamaProvider.php`, upewnij się, że używa zmiennej środowiskowej:

```php
// app/Providers/OllamaProvider.php
$ollamaUrl = env('OLLAMA_URL', 'http://localhost:11434');

// Użyj $ollamaUrl zamiast hardcoded localhost
```

---

## 🔒 Bezpieczeństwo

### Firewall

Upewnij się, że firewall na serwerze OVH pozwala na port WireGuard:

```bash
# Sprawdź port WireGuard (domyślnie 51820)
sudo ufw allow 51820/udp
```

### Basic Auth (opcjonalnie)

Jeśli chcesz dodatkowe zabezpieczenie, skonfiguruj Nginx reverse proxy z Basic Auth:

```bash
# Na serwerze OVH
./scripts/setup-nginx-ovh.sh
```

---

## 🐛 Rozwiązywanie problemów

### Problem: "Connection refused"

**Rozwiązanie:**
1. Sprawdź czy WireGuard działa: `wg show`
2. Sprawdź czy Ollama działa lokalnie: `curl http://localhost:11434/api/tags`
3. Sprawdź ping: `ping 10.0.0.1`

### Problem: "No route to host"

**Rozwiązanie:**
1. Sprawdź konfigurację WireGuard: `wg show`
2. Sprawdź IP forwarding: `sysctl net.ipv4.ip_forward`
3. Sprawdź iptables: `sudo iptables -L -n -v`

### Problem: Waldus API nie może się połączyć

**Rozwiązanie:**
1. Sprawdź czy Waldus API ma dostęp do WireGuard VPN
2. Sprawdź czy `OLLAMA_URL` w `.env` jest poprawny
3. Sprawdź logi Waldus API

---

## 📊 Przykładowa konfiguracja

### .env w waldus-api

```env
# Ollama przez WireGuard VPN
OLLAMA_URL=http://10.0.0.1:11434

# Jeśli używasz Basic Auth (Nginx)
# OLLAMA_USER=ollama-user
# OLLAMA_PASSWORD=haslo
```

### Sprawdzenie konfiguracji

```bash
# Na serwerze OVH
wg show
curl http://10.0.0.1:11434/api/tags

# Z Waldus API
curl http://10.0.0.1:11434/api/tags
```

---

## ✅ Checklist

- [ ] WireGuard VPN skonfigurowany i działający
- [ ] Ollama dostępne przez VPN (`curl http://10.0.0.1:11434/api/tags`)
- [ ] Waldus API ma dostęp do WireGuard VPN (jeśli na innym serwerze)
- [ ] `.env` w `waldus-api` zaktualizowany z `OLLAMA_URL`
- [ ] Test połączenia z Waldus API działa
- [ ] Firewall skonfigurowany (port 51820/udp)

---

**Gotowe!** Bot powinien teraz móc łączyć się z Ollama przez WireGuard VPN. 🎉

