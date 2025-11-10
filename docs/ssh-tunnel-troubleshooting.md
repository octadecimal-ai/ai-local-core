# 🔧 SSH Tunnel - Rozwiązywanie problemów

## Problem: Remote Port Forwarding nie działa

**Błąd:**
```
Warning: remote port forwarding failed for listen port 11434
```

### Przyczyny:

1. **Port jest już zajęty** - inny proces używa portu 11434
2. **GatewayPorts=no** - domyślnie SSH nie pozwala na forwardowanie portów z zewnątrz
3. **Brak uprawnień** - użytkownik nie ma uprawnień do forwardowania portów
4. **Ograniczenia sshd_config** - administrator serwera zablokował port forwarding

### Rozwiązanie 1: Użyj innego portu

```bash
# Zamiast 11434 użyj 11435 lub innego portu
autossh -M 0 -N -R 11435:localhost:11434 waldusz@waldus-server -p 22
```

### Rozwiązanie 2: Local Port Forwarding (odwrotne)

Zamiast forwardować z serwera do lokalnego PC, forwarduj z lokalnego PC do serwera:

**Na serwerze OVH:**
```bash
# Uruchom SSH który łączy się z lokalnym PC i forwarduje port
ssh -L 11435:localhost:11434 piotradamczyk@local-pc-ip -N
```

**Problem:** Wymaga to publicznego IP lub innego tunelu do lokalnego PC.

### Rozwiązanie 3: Nginx Reverse Proxy na serwerze OVH

Najlepsze rozwiązanie - użyj Nginx jako reverse proxy:

1. **Na lokalnym PC** - uruchom SSH z remote forwarding (nawet jeśli port jest zajęty, użyj bind_address):
```bash
ssh -R 127.0.0.1:11435:localhost:11434 waldusz@waldus-server -N
```

2. **Na serwerze OVH** - skonfiguruj Nginx:
```bash
# /etc/nginx/sites-available/ollama
server {
    listen 80;
    server_name ollama.example.com;
    
    location / {
        proxy_pass http://127.0.0.1:11435;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Rozwiązanie 4: Sprawdź konfigurację SSH na serwerze

**Na serwerze OVH:**
```bash
# Sprawdź sshd_config
sudo grep -E "(GatewayPorts|AllowTcpForwarding)" /etc/ssh/sshd_config

# Jeśli GatewayPorts=no, zmień na:
sudo nano /etc/ssh/sshd_config
# Dodaj/zmień:
GatewayPorts yes
AllowTcpForwarding yes

# Przeładuj SSH
sudo systemctl reload sshd
```

### Rozwiązanie 5: Użyj WireGuard VPN

Jeśli SSH port forwarding nie działa, użyj WireGuard VPN - to najlepsze rozwiązanie:

```bash
./scripts/setup-wireguard-ovh.sh
```

WireGuard nie ma problemów z port forwarding i jest szybszy.

---

## Sprawdzanie czy port jest zajęty

**Na serwerze OVH:**
```bash
# Sprawdź co nasłuchuje na porcie 11434
sudo lsof -i :11434
sudo netstat -tlnp | grep 11434
sudo ss -tlnp | grep 11434
```

**Jeśli port jest zajęty:**
- Użyj innego portu (np. 11435, 11436)
- Zatrzymaj proces który używa portu
- Zmień konfigurację Ollama na inny port

---

## Testowanie połączenia

**1. Sprawdź czy tunel działa:**
```bash
# Na lokalnym PC
ps aux | grep autossh | grep 11434

# Sprawdź logi
tail -f /tmp/ssh-tunnel-ollama.log
```

**2. Test z serwera OVH:**
```bash
# Zaloguj się na serwer
ssh waldus-server

# Test połączenia
curl http://localhost:11434/api/tags
# lub
curl http://127.0.0.1:11434/api/tags
```

**3. Test z zewnątrz:**
```bash
# Jeśli GatewayPorts=yes
curl http://OVH_IP:11434/api/tags
```

---

## Alternatywne rozwiązania

### 1. Cloudflare Tunnel
Jeśli SSH nie działa, użyj Cloudflare Tunnel:
```bash
./scripts/setup-cloudflare-tunnel.sh
```

### 2. Tailscale VPN
Najlepsze rozwiązanie dla produkcyjnego:
```bash
./scripts/setup-tailscale.sh
```

### 3. WireGuard VPN
Najszybsze i najbezpieczniejsze:
```bash
./scripts/setup-wireguard-ovh.sh
```

---

## Najczęstsze problemy

### Problem: "Connection refused"
**Rozwiązanie:** Sprawdź czy Ollama działa lokalnie:
```bash
curl http://localhost:11434/api/tags
```

### Problem: "Permission denied"
**Rozwiązanie:** Sprawdź uprawnienia klucza SSH:
```bash
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### Problem: Tunel się rozłącza
**Rozwiązanie:** Użyj autossh zamiast ssh:
```bash
autossh -M 0 -N -R 11434:localhost:11434 waldusz@waldus-server
```

---

## Rekomendacja

Jeśli SSH port forwarding nie działa, najlepsze rozwiązania w kolejności:

1. **WireGuard VPN** - najszybsze, najbezpieczniejsze
2. **Tailscale VPN** - łatwe w konfiguracji
3. **Nginx Reverse Proxy** - jeśli masz już Nginx
4. **Cloudflare Tunnel** - szybki start

