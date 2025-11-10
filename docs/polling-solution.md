# 🔄 Rozwiązanie Polling - Proste i niezawodne

## 📋 Koncepcja

Zamiast skomplikowanego WireGuard VPN, używamy prostego rozwiązania polling:

1. **Lokalny serwer (MacOS)** - co kilka sekund pyta serwer OVH czy ma zapytanie
2. **Serwer OVH** - przechowuje zapytania i czeka na odpowiedzi
3. **Jeśli jest zapytanie** - lokalny serwer przetwarza przez Ollama i zwraca odpowiedź

## 🏗️ Architektura

```
[Waldus API] → [Serwer OVH] ← [Lokalny PC z Ollama]
                      ↑              ↓
                      └─── Polling ──┘
```

**Przepływ:**
1. Waldus API wysyła zapytanie do serwera OVH
2. Serwer OVH zapisuje zapytanie w kolejce
3. Lokalny PC pyta serwer OVH: "Masz coś dla mnie?"
4. Jeśli tak - lokalny PC pobiera zapytanie
5. Lokalny PC przetwarza przez Ollama
6. Lokalny PC zwraca odpowiedź na serwer OVH
7. Serwer OVH zwraca odpowiedź do Waldus API

## ✅ Zalety

- ✅ **Proste** - nie wymaga VPN, tuneli, kluczy
- ✅ **Niezawodne** - działa przez standardowe HTTP
- ✅ **Bezpieczne** - można dodać autoryzację
- ✅ **Elastyczne** - łatwo zmienić interwał polling
- ✅ **Działa z NAT** - nie wymaga publicznego IP

## 📦 Instalacja

### Lokalnie (MacOS)

1. **Uruchom klienta polling:**
```bash
./scripts/start-polling-client.sh
```

2. **Lub ręcznie:**
```bash
source venv/bin/activate
python3 -m src.polling.client --server https://waldus-server.com --interval 5
```

### Konfiguracja

Zmienne środowiskowe:
```bash
export POLLING_SERVER_URL="https://waldus-server.com"
export POLLING_INTERVAL=5  # sekundy
```

## 🔧 API Endpointy (na serwerze OVH)

### 1. GET /api/ollama/poll
**Pytanie lokalnego PC:** "Masz coś dla mnie?"

**Odpowiedź jeśli jest zapytanie:**
```json
{
  "has_request": true,
  "request": {
    "id": "request-123",
    "prompt": "Co to jest Python?",
    "system_prompt": "Jesteś pomocnym asystentem",
    "model": "qwen2.5:7b",
    "temperature": 0.7,
    "max_tokens": 2000
  }
}
```

**Odpowiedź jeśli brak zapytania:**
- Status: 204 No Content
- Lub: `{"has_request": false}`

### 2. POST /api/ollama/response
**Wysyłanie odpowiedzi z lokalnego PC:**

```json
{
  "id": "request-123",
  "response": "Python to język programowania...",
  "model": "qwen2.5:7b",
  "success": true
}
```

**Odpowiedź serwera:**
- Status: 200 OK

### 3. POST /api/ollama/request (dla Waldus API)
**Wysyłanie zapytania z Waldus API:**

```json
{
  "prompt": "Co to jest Python?",
  "system_prompt": "Jesteś pomocnym asystentem",
  "model": "qwen2.5:7b",
  "temperature": 0.7,
  "max_tokens": 2000
}
```

**Odpowiedź serwera:**
```json
{
  "id": "request-123",
  "status": "queued"
}
```

### 4. GET /api/ollama/status/:id
**Sprawdzanie statusu zapytania:**

```json
{
  "id": "request-123",
  "status": "processing" | "completed" | "error",
  "response": "Python to język...",  // jeśli completed
  "error": "..."  // jeśli error
}
```

## 🚀 Uruchomienie

### Lokalnie (MacOS)

```bash
# Podstawowe uruchomienie
./scripts/start-polling-client.sh

# Z własnymi parametrami
POLLING_SERVER_URL="https://waldus-server.com" \
POLLING_INTERVAL=3 \
./scripts/start-polling-client.sh
```

### Jako systemd service (Linux) lub launchd (MacOS)

**MacOS (launchd):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ollama.polling</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/ai-local-core/scripts/start-polling-client.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>POLLING_SERVER_URL</key>
        <string>https://waldus-server.com</string>
        <key>POLLING_INTERVAL</key>
        <string>5</string>
    </dict>
</dict>
</plist>
```

## 🔒 Bezpieczeństwo

### Autoryzacja (opcjonalnie)

Dodaj API key do requestów:

```python
headers = {
    'Authorization': f'Bearer {API_KEY}',
    'X-Client-ID': 'local-ollama-client'
}
```

### Rate Limiting

Na serwerze OVH dodaj rate limiting dla endpointów polling.

## 🐛 Rozwiązywanie problemów

### Problem: Klient nie łączy się z serwerem

```bash
# Sprawdź połączenie
curl https://waldus-server.com/api/ollama/poll

# Sprawdź logi
tail -f ~/.wireguard/logs/wireguard.log  # jeśli używasz loggera
```

### Problem: Brak odpowiedzi

- Sprawdź czy Ollama działa: `curl http://localhost:11434/api/tags`
- Sprawdź logi klienta polling
- Sprawdź czy serwer OVH zwraca zapytania

## 📊 Monitoring

### Logi klienta

Klient wyświetla w konsoli:
- 📨 Otrzymane zapytania
- 📝 Przetwarzanie
- ✅ Wysłane odpowiedzi
- ⚠️  Błędy

### Metryki (opcjonalnie)

Można dodać:
- Liczba przetworzonych zapytań
- Średni czas odpowiedzi
- Błędy

## ✅ Checklist implementacji

- [ ] Klient polling działa lokalnie
- [ ] Serwer OVH ma endpointy API
- [ ] Waldus API wysyła zapytania do serwera OVH
- [ ] Lokalny PC przetwarza zapytania przez Ollama
- [ ] Odpowiedzi wracają do Waldus API
- [ ] Autoryzacja (opcjonalnie)
- [ ] Monitoring i logi

---

**To rozwiązanie jest znacznie prostsze niż WireGuard!** 🎉

