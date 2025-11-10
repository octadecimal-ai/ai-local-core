# ai-local-core - Lokalne usługi ML/LLM dla Waldus API

Projekt zawiera lokalne implementacje usług Machine Learning i Large Language Models, które mogą być używane jako fallback dla zewnętrznych API.

## 📋 Zawartość projektu

- **Ollama Client** - Komunikacja z lokalnym serwerem Ollama (LLM)
- **Image Description** - Rozpoznawanie i opisywanie obrazków (BLIP model)
- **Translation** - Tłumaczenie tekstu
- **API Server** - Flask API server dla wszystkich usług

## 🚀 Szybki start

### Instalacja

1. **Utwórz virtual environment (zalecane):**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # Linux/Mac
   # lub
   venv\Scripts\activate  # Windows
   ```

2. **Zainstaluj zależności Python:**
   ```bash
   pip install --upgrade pip setuptools wheel
   pip install -r requirements.txt
   ```

   **Uwaga:** Instalacja może zająć kilka minut, szczególnie `torch` i `transformers` są duże.

3. **Aktywuj środowisko (skrypt pomocniczy):**
   ```bash
   source scripts/activate.sh
   ```

2. **Zainstaluj Ollama** (jeśli jeszcze nie masz):
   - MacOS: `brew install ollama` lub pobierz z [ollama.ai](https://ollama.ai/download)
   - Linux: `curl -fsSL https://ollama.ai/install.sh | sh`

3. **Pobierz modele Ollama:**
   ```bash
   ollama pull llama3.1:8b
   ollama pull phi3:medium
   ```

## 📁 Struktura projektu

```
ai-local-core/
├── src/
│   ├── ollama/          # Komunikacja z Ollama API
│   ├── image/           # Rozpoznawanie obrazków
│   ├── translation/     # Tłumaczenie tekstu
│   └── api/             # Flask API server
├── config/              # Konfiguracje (development/production)
├── scripts/             # Skrypty pomocnicze
├── docs/                # Dokumentacja
└── requirements.txt     # Zależności Python
```

## 🔧 Użycie

### Ollama Client

#### CLI (kompatybilność z waldus-api)

```bash
# Podstawowe użycie
python src/ollama/complete.py '{"user": "Hello, how are you?", "temperature": 0.7}'

# Z system prompt
python src/ollama/complete.py '{"system": "You are a helpful assistant", "user": "What is Python?", "max_tokens": 100}'
```

#### Python API (nowy OllamaClient)

```python
from ollama.client import OllamaClient

# Utwórz klienta
client = OllamaClient()

# Sprawdź dostępność
if client.check_health():
    # Chat completion
    result = client.chat(
        user="Hello, how are you?",
        system="You are a helpful assistant",
        temperature=0.7,
        max_tokens=100
    )
    print(result['text'])
    
    # Lista modeli
    models = client.list_models()
    for model in models:
        print(model['name'])
    
    # Generate
    result = client.generate(
        prompt="Write a short poem about programming",
        temperature=0.8
    )
    print(result['text'])
```

#### Przykład użycia

```bash
python src/ollama/example.py
```

#### Prosty skrypt do zadawania pytań

Edytuj zmienne w `scripts/ask_ollama.py` i uruchom:

```bash
# Edytuj PYTANIE, SYSTEM_PROMPT, MODEL, etc. w scripts/ask_ollama.py
python scripts/ask_ollama.py
```

Przykład konfiguracji w `scripts/ask_ollama.py`:
```python
PYTANIE = "Co to jest Python? Odpowiedz krótko."
SYSTEM_PROMPT = "Jesteś pomocnym asystentem. Odpowiadaj po polsku."
MODEL = None  # None = użyj domyślnego
TEMPERATURE = 0.7
MAX_TOKENS = 200
```

### Image Description (CLI)

```bash
# Opisz obraz z URL
python src/image/describe.py "https://example.com/image.jpg" 50

# Opisz obraz z lokalnego pliku
python src/image/describe.py "/path/to/image.jpg" 50
```

### Translation (CLI)

```bash
# Tłumacz na polski
python src/translation/translate.py "Hello world" pl

# Tłumacz na niemiecki
python src/translation/translate.py "Hello world" de
```

### API Server

```bash
# Uruchom Flask API server
python src/api/server.py

# Server będzie dostępny na http://127.0.0.1:5001
```

## 🔗 Integracja z Waldus API

Po migracji, w `waldus-api` należy zaktualizować ścieżki:

1. **Dodaj do `.env`:**
   ```env
   AI_LOCAL_CORE_PATH=/Users/piotradamczyk/Projects/Octadecimal/ai-local-core
   ```

2. **Aktualizuj `OllamaProvider.php`:**
   ```php
   $aiLocalCorePath = env('AI_LOCAL_CORE_PATH');
   $scriptPath = $aiLocalCorePath . '/src/ollama/complete.py';
   ```

3. **Aktualizuj `ImageDescriptionService.php`:**
   ```php
   $aiLocalCorePath = env('AI_LOCAL_CORE_PATH');
   $this->pythonScript = $aiLocalCorePath . '/src/image/describe.py';
   $translateScript = $aiLocalCorePath . '/src/translation/translate.py';
   ```

## 📚 Dokumentacja

- [Plan działania i architektura](docs/WL-25-local-support-ollama.md)
- [Instalacja i setup](docs/installation.md)
- [Setup tłumaczenia](docs/translation-setup.md)
- [Plan migracji Pythona](docs/python-migration.md)
- [Testy jednostkowe - pełna dokumentacja](docs/testing.md)
- [Konfiguracja z serwerem OVH](docs/ovh-server-setup.md) ⭐
- [Konfiguracja tunelu (Cloudflare/Tailscale)](docs/tunnel-setup.md)
- [Rekomendacje modeli Ollama](docs/model-recommendations.md)

## 🧪 Testy jednostkowe

### Instalacja pytest (jeśli jeszcze nie zainstalowane)

```bash
source venv/bin/activate
pip install pytest pytest-cov
```

### Uruchamianie testów

#### Podstawowe komendy

```bash
# Aktywuj virtual environment
source venv/bin/activate

# Wszystkie testy jednostkowe
pytest tests/unit/ -v

# Wszystkie testy (unit + integration)
pytest tests/ -v

# Tylko testy OllamaClient
pytest tests/unit/test_ollama_client.py -v

# Tylko testy Translation
pytest tests/unit/test_translation.py -v
```

#### Z raportem pokrycia kodem (coverage)

```bash
# Coverage w terminalu
pytest tests/ --cov=src --cov-report=term-missing

# Coverage z raportem HTML (otwórz htmlcov/index.html)
pytest tests/ --cov=src --cov-report=html --cov-report=term-missing

# Tylko testy jednostkowe z coverage
pytest tests/unit/ --cov=src --cov-report=term-missing
```

#### Użycie skryptu pomocniczego

```bash
# Uruchom wszystkie testy z coverage
./scripts/run-tests.sh

# Lub z dodatkowymi opcjami pytest
./scripts/run-tests.sh -v --tb=short
```

### Przykładowe wyniki

```bash
$ pytest tests/unit/ -v

============================= test session starts ==============================
platform darwin -- Python 3.12.8, pytest-9.0.0
collected 18 items

tests/unit/test_ollama_client.py::TestOllamaClient::test_init_default PASSED
tests/unit/test_ollama_client.py::TestOllamaClient::test_chat_success PASSED
...
tests/unit/test_translation.py::TestTranslation::test_translate_text_pl PASSED

============================== 18 passed in 3.48s ==============================
```

### Status testów

- ✅ **OllamaClient** - 15 testów, wszystkie przechodzą (96% coverage)
- ✅ **Translation** - 3 testy, wszystkie przechodzą
- ⏳ Image description - do dodania
- ⏳ API server - do dodania

### Struktura testów

```
tests/
├── unit/                    # Testy jednostkowe
│   ├── test_ollama_client.py    # 15 testów
│   └── test_translation.py      # 3 testy
└── integration/             # Testy integracyjne (do dodania)
```

### Opcje pytest

```bash
# Verbose output (szczegółowe)
pytest tests/ -v

# Bardzo szczegółowe (pokazuje printy)
pytest tests/ -v -s

# Krótki traceback przy błędach
pytest tests/ --tb=short

# Tylko pierwszy błąd
pytest tests/ -x

# Uruchom konkretny test
pytest tests/unit/test_ollama_client.py::TestOllamaClient::test_chat_success -v
```

### Troubleshooting

**Problem: ModuleNotFoundError**
```bash
# Upewnij się, że jesteś w katalogu projektu
cd /Users/piotradamczyk/Projects/Octadecimal/ai-local-core

# Aktywuj virtual environment
source venv/bin/activate

# Sprawdź czy pytest jest zainstalowany
pip list | grep pytest
```

**Problem: Import errors**
```bash
# Upewnij się, że ścieżka do src jest poprawna
# Testy automatycznie dodają src do PYTHONPATH
```

### Test importów
```bash
# Użyj skryptu pomocniczego
./scripts/test-imports.sh

# Lub ręcznie
source venv/bin/activate
python3 -c "import sys; sys.path.insert(0, 'src'); from ollama.complete import complete; print('✅ OK')"
```

### Test funkcjonalności
```bash
source venv/bin/activate

# Test Ollama (wymaga uruchomionego Ollama)
python src/ollama/complete.py '{"user": "Test"}'

# Test Image Description (wymaga modelu BLIP - załaduje się automatycznie)
python src/image/describe.py "https://picsum.photos/800/600" 50

# Test Translation
python src/translation/translate.py "Hello world" pl
```

## 🔄 Rozwiązanie Polling (Rekomendowane) ⭐⭐⭐

Najprostsze rozwiązanie - lokalny serwer pyta serwer OVH czy ma zapytanie:

```bash
# Uruchom klienta polling
./scripts/start-polling-client.sh

# Z własnymi parametrami
POLLING_SERVER_URL="https://waldus-server.com" \
POLLING_INTERVAL=5 \
./scripts/start-polling-client.sh
```

**Jak to działa:**
1. Lokalny PC co kilka sekund pyta serwer OVH: "Masz coś dla mnie?"
2. Jeśli serwer ma zapytanie - lokalny PC przetwarza przez Ollama
3. Lokalny PC zwraca odpowiedź na serwer OVH
4. Serwer OVH zwraca odpowiedź do Waldus API

**Zalety:**
- ✅ Proste - nie wymaga VPN, tuneli, kluczy
- ✅ Niezawodne - działa przez standardowe HTTP
- ✅ Działa z NAT - nie wymaga publicznego IP

**Dokumentacja:** [Rozwiązanie Polling](docs/polling-solution.md)

## 🌐 Konfiguracja tunelu (dostęp z zewnątrz)

Aby umożliwić dostęp do Ollama z serwera Waldus API, musisz skonfigurować tunel.

### Opcja 1: Własny serwer OVH ⭐⭐⭐ (Rekomendowane)

Jeśli masz serwer na OVH, możesz skonfigurować własny tunel:

**SSH Tunnel (najprostsze):**
```bash
./scripts/setup-ssh-tunnel.sh
```

**WireGuard VPN (najlepsze):**
```bash
./scripts/setup-wireguard-ovh.sh
```

**Nginx Reverse Proxy z SSL:**
```bash
# Na serwerze OVH
./scripts/setup-nginx-ovh.sh
```

**Dokumentacja:** [Konfiguracja z serwerem OVH](docs/ovh-server-setup.md)

### Opcja 2: Cloudflare Tunnel (szybki start)

```bash
# Instalacja (MacOS)
brew install cloudflared

# Lub użyj skryptu
./scripts/setup-cloudflare-tunnel.sh

# Uruchomienie tunelu
./scripts/start-tunnel.sh
```

**Wynik:** Otrzymasz URL (np. `https://xxx.trycloudflare.com`), który możesz użyć w konfiguracji Waldus API.

### Opcja 3: Tailscale VPN

```bash
# Instalacja (MacOS)
brew install tailscale

# Lub użyj skryptu
./scripts/setup-tailscale.sh

# Połączenie
tailscale up
```

**Wynik:** Otrzymasz Tailscale IP (np. `100.x.x.x`), które możesz użyć w konfiguracji.

### Dokumentacja

- [Konfiguracja z serwerem OVH](docs/ovh-server-setup.md) ⭐
- [Konfiguracja tunelu (Cloudflare/Tailscale)](docs/tunnel-setup.md)

## 🔒 Bezpieczeństwo

- Wszystkie skrypty są przeznaczone do lokalnego użycia
- Dla produkcyjnego użycia rozważ:
  - Reverse proxy z autoryzacją (Nginx) - zobacz [dokumentację tunelu](docs/tunnel-setup.md#-bezpieczeństwo)
  - Cloudflare Tunnel lub Tailscale dla bezpiecznego dostępu
  - Rate limiting

## 📝 Status

- ✅ Migracja Pythona z waldus-api
- ✅ Struktura projektu
- ⏳ OllamaClient implementation
- ⏳ Testy jednostkowe
- ⏳ Integracja z Waldus API

## 🤝 Wsparcie

W razie problemów sprawdź:
- [Dokumentację Ollama](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Dokumentację BLIP](https://huggingface.co/Salesforce/blip-image-captioning-base)
- Logi w `.dev/logs/cursor/`

---

**Autor:** Auto (Agent Router by Cursor)  
**Data utworzenia:** 2025-11-09  
**Status:** 🟡 W rozwoju

