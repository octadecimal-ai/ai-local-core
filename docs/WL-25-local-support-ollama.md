# WL-25: ai-local-core - Self-hosted Ollama na RTX 3060 🖥️

## 📋 Opis zadania

Utworzenie lokalnego wsparcia dla Waldus API poprzez uruchomienie własnego LLM (Ollama) na dedykowanym PC z RTX 3060 12GB. Projekt ma na celu zapewnienie fallbacku dla zewnętrznych API LLM oraz pełnej kontroli nad danymi i kosztami.

---

## 🖥️ Specyfikacja sprzętu

**CPU:** AMD Ryzen 5 5600X (6 cores, 12 threads)  
**RAM:** 16 GB  
**GPU:** NVIDIA GeForce RTX 3060 (12 GB VRAM)  
**System:** Ubuntu Server  
**Internet:** Światłowód UPC/Play (stałe IP, ale problemy z publicznym dostępem)  
**Rozwiązanie tunelu:** ngrok (do zmiany na Cloudflare Tunnel lub Tailscale)

---

## 🔍 Analiza możliwości

### ✅ Doskonała konfiguracja dla Ollama!

**RTX 3060 12GB VRAM** to idealna karta dla lokalnego LLM:
- Wystarczająca VRAM dla większości modeli 7B-13B w wersji quantized
- CUDA acceleration zapewnia wysoką wydajność
- 12GB VRAM pozwala na uruchomienie większych modeli niż na CPU

### Modele możliwe do uruchomienia

#### Modele 7B (Q4/Q5) - ✅ Idealne dla RTX 3060

| Model | VRAM | RAM | Wydajność (RTX 3060) | Jakość |
|-------|------|-----|---------------------|--------|
| **Llama 3.1 8B Q4** | ~6-7 GB | ~8 GB | ~30-50 tok/s | ⭐⭐⭐⭐⭐ |
| **Mistral 7B Q4** | ~5-6 GB | ~7 GB | ~35-55 tok/s | ⭐⭐⭐⭐⭐ |
| **Llama 3.2 7B Q4** | ~6-7 GB | ~8 GB | ~30-50 tok/s | ⭐⭐⭐⭐⭐ |
| **Phi-3 Medium 3.8B** | ~3-4 GB | ~5 GB | ~60-80 tok/s | ⭐⭐⭐⭐ |
| **Gemma 2 9B Q4** | ~7-8 GB | ~9 GB | ~25-40 tok/s | ⭐⭐⭐⭐⭐ |

#### Modele 13B (Q4) - ⚠️ Możliwe, ale na granicy

| Model | VRAM | RAM | Wydajność | Status |
|-------|------|-----|-----------|--------|
| **Llama 3.1 13B Q4** | ~9-10 GB | ~12 GB | ~15-25 tok/s | ⚠️ Możliwe, ale wolne |
| **Mistral 13B Q4** | ~9-10 GB | ~12 GB | ~15-25 tok/s | ⚠️ Możliwe, ale wolne |

**Wnioski:**
- ✅ **Rekomendowane:** Modele 7B-9B w Q4 - doskonała wydajność (30-50 tok/s)
- ⚠️ **Możliwe:** Modele 13B w Q4 - wolniejsze (15-25 tok/s), ale działają
- ❌ **Niewskazane:** Modele >13B lub FP16 - nie zmieszczą się w 12GB VRAM

### Wydajność vs. API

| Provider | Wydajność | Koszt | Status |
|----------|-----------|-------|--------|
| **RTX 3060 (Llama 3.1 8B Q4)** | ~30-50 tok/s | 0 PLN (energia) | ✅ Doskonałe! |
| **Anthropic Claude** | ~50-100 tok/s | Pay-per-use | ⚠️ Kosztowne |
| **Groq API** | ~500+ tok/s | Darmowy tier | ⚠️ Zewnętrzne API |
| **OpenAI GPT-3.5** | ~50-100 tok/s | Pay-per-use | ⚠️ Kosztowne |

**Wnioski:**
- RTX 3060 daje **porównywalną wydajność** do API (30-50 tok/s vs. 50-100 tok/s)
- **Zero kosztów** (poza energią elektryczną ~50-100 PLN/mies.)
- **Pełna prywatność** danych
- **Brak limitów API**

---

## 🌐 Problemy z publicznym IP i rozwiązania

### Problem: Stałe IP bez publicznego dostępu

**Możliwe przyczyny:**
1. **CGNAT (Carrier-Grade NAT)** - Play/UPC używa NAT, więc IP nie jest publiczne
2. **Firewall ISP** - blokada portów przychodzących
3. **Router configuration** - brak port forwarding

### Rozwiązanie 1: ngrok ⚠️ (obecne)

**Zalety:**
- ✅ Szybka konfiguracja
- ✅ Działa od razu
- ✅ Darmowy tier dostępny

**Wady:**
- ❌ **Limit darmowego tier:** 40 connections/min, 2GB transfer/mies.
- ❌ **Timeout:** połączenia mogą się rozłączać
- ❌ **Bezpieczeństwo:** dane przechodzą przez serwery ngrok
- ❌ **Niezawodność:** może być niestabilne dla produkcyjnego użycia
- ❌ **Koszty:** płatny plan ($8/mies.) dla większego ruchu

### Rozwiązanie 2: Cloudflare Tunnel (Cloudflared) ⭐ (REKOMENDOWANE)

**Zalety:**
- ✅ **Darmowe** - bez limitów transferu
- ✅ **Bezpieczne** - end-to-end encryption
- ✅ **Niezawodne** - stabilne połączenia
- ✅ **Szybsze** - lepsza wydajność niż ngrok
- ✅ **Darmowa domena** - możliwość użycia darmowej domeny Cloudflare

**Wady:**
- ⚠️ Wymaga rejestracji w Cloudflare (darmowe)
- ⚠️ Konfiguracja nieco bardziej złożona niż ngrok

**Instalacja:**
```bash
# Pobierz cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared

# Uruchom tunnel
cloudflared tunnel --url http://localhost:11434
```

### Rozwiązanie 3: Tailscale / ZeroTier (VPN Mesh) ⭐⭐ (NAJLEPSZE dla bezpieczeństwa)

**Zalety:**
- ✅ **Najbezpieczniejsze** - VPN mesh, end-to-end encryption
- ✅ **Darmowe** - do 100 urządzeń
- ✅ **Niezawodne** - stabilne połączenia
- ✅ **Proste** - łatwa konfiguracja
- ✅ **Bez pośredników** - bezpośrednie połączenie P2P

**Wady:**
- ⚠️ Wymaga instalacji na obu końcach (serwer + klient API)

**Instalacja:**
```bash
# Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# ZeroTier
curl -s https://install.zerotier.com | sudo bash
sudo zerotier-cli join <network-id>
```

### Rozwiązanie 4: WireGuard VPN (zaawansowane)

**Zalety:**
- ✅ **Najszybsze** - niski overhead
- ✅ **Bezpieczne** - nowoczesna kryptografia
- ✅ **Darmowe** - open source

**Wady:**
- ❌ Wymaga własnego serwera VPN (można użyć VPS)
- ❌ Konfiguracja bardziej złożona

---

## 🏗️ Architektura rozwiązania

### Opcja A: Cloudflare Tunnel (dla szybkiego startu) ⭐

```
[Waldus API] → [Cloudflare Tunnel] → [Ollama na PC (localhost:11434)]
```

**Kroki:**
1. Zainstaluj Ollama na Ubuntu Server
2. Skonfiguruj Ollama API (domyślnie port 11434)
3. Uruchom Cloudflare Tunnel: `cloudflared tunnel --url http://localhost:11434`
4. Uzyskaj publiczny URL (np. `https://ollama-xxx.trycloudflare.com`)
5. Skonfiguruj FallbackService w Waldus API do używania tego URL

**Zalety:**
- ✅ Szybka konfiguracja (15 minut)
- ✅ Darmowe
- ✅ Wystarczające dla fazy 1-2

### Opcja B: Tailscale (dla produkcyjnego użycia) ⭐⭐

```
[Waldus API] → [Tailscale VPN] → [Ollama na PC (tailscale-ip:11434)]
```

**Kroki:**
1. Zainstaluj Tailscale na Ubuntu Server
2. Zainstaluj Tailscale na serwerze Waldus API (lub użyj Tailscale w Docker)
3. Skonfiguruj Ollama do nasłuchiwania na IP Tailscale
4. Skonfiguruj FallbackService do używania Tailscale IP

**Zalety:**
- ✅ Najbezpieczniejsze
- ✅ Najbardziej niezawodne
- ✅ Zero kosztów
- ✅ Idealne dla produkcyjnego użycia

---

## 🔒 Bezpieczeństwo Ollama API

### Problem: Ollama domyślnie nie ma autoryzacji

**Ryzyka:**
- ❌ Każdy z dostępem do URL może używać Ollama
- ❌ Możliwość nadużyć (wysokie koszty energii)
- ❌ Brak rate limiting

### Rozwiązanie: Reverse Proxy z autoryzacją

**Nginx + Basic Auth:**

```nginx
server {
    listen 11434;
    server_name ollama.local;

    location / {
        auth_basic "Ollama API";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        proxy_pass http://localhost:11434;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Lub użyj Ollama z API key (jeśli dostępne w przyszłości)**

---

## 🎯 Plan implementacji

### Faza 1: Setup podstawowy (2-3 godziny) ⚡

1. ✅ Zainstaluj Ollama na Ubuntu Server
2. ✅ Zainstaluj wybrany model (Llama 3.1 8B Q4 lub Mistral 7B Q4)
3. ✅ Przetestuj lokalnie: `curl http://localhost:11434/api/generate`
4. ✅ Skonfiguruj Cloudflare Tunnel dla szybkiego startu

### Faza 2: Bezpieczeństwo (1-2 godziny) 🔒

1. ✅ Skonfiguruj Nginx reverse proxy z Basic Auth
2. ✅ Przetestuj dostęp przez tunnel
3. ✅ Skonfiguruj firewall (ufw) - tylko porty potrzebne

### Faza 3: Integracja z Waldus API (2-3 godziny) 🔗

1. ✅ Utwórz OllamaProvider w Waldus API
2. ✅ Zintegruj z FallbackService
3. ✅ Dodaj monitoring i logowanie
4. ✅ Przetestuj fallback (wyłącz Anthropic, sprawdź czy używa Ollama)

### Faza 4: Optymalizacja (opcjonalnie) 🚀

1. ⚠️ Rozważ Tailscale zamiast Cloudflare Tunnel (dla produkcyjnego)
2. ⚠️ Dodaj rate limiting
3. ⚠️ Monitoruj zużycie energii
4. ⚠️ Rozważ automatyczne wyłączanie GPU gdy nieużywane

---

## 💰 Koszty vs. korzyści

| Aspekt | Self-hosted (RTX 3060) | API (Anthropic/Groq) |
|--------|------------------------|---------------------|
| **Koszt miesięczny** | ~50-100 PLN (energia) | ~200-500 PLN (API) |
| **Wydajność** | 30-50 tok/s | 50-500 tok/s |
| **Prywatność** | ✅ Pełna | ❌ Dane u providera |
| **Niezależność** | ✅ Brak limitów | ⚠️ Limity API |
| **Złożoność** | ⚠️ Wymaga zarządzania | ✅ Zero zarządzania |
| **Niezawodność** | ⚠️ Zależy od PC/Internetu | ✅ Wysoka |

**Wnioski:**
- ✅ **Oszczędność:** ~100-400 PLN/mies. (vs. API)
- ✅ **Wydajność:** Wystarczająca dla fallbacku (30-50 tok/s)
- ✅ **Prywatność:** Pełna kontrola
- ⚠️ **Złożoność:** Wymaga zarządzania, ale warto

---

## ✅ Finalna rekomendacja

**✅ ZDECYDOWANIE TAK - Self-hosted Ollama na RTX 3060**

**Plan działania:**
1. **Teraz:** Zainstaluj Ollama + Cloudflare Tunnel (2-3h)
2. **Faza 1:** Użyj jako fallback w kontekstowym fallbacku (#1 z WL-2)
3. **Faza 3:** Zintegruj z FallbackService jako alternatywa dla Anthropic
4. **Długoterminowo:** Rozważ Tailscale zamiast ngrok dla lepszego bezpieczeństwa

**Rekomendowany model:** Llama 3.1 8B Q4 lub Mistral 7B Q4 (najlepsza jakość przy 30-50 tok/s)

---

## 📝 Notatki implementacyjne

### Status Ollama
- ✅ Ollama jest już zainstalowana na Ubuntu Server
- ✅ Ollama jest zainstalowana na MacOS (MacBook Pro M1) - wersja 0.11.6
- ⏳ Do zrobienia: Konfiguracja tunelu, bezpieczeństwo, integracja

### Zależności z innymi zadaniami
- **WL-2:** Dopracowanie fallbacku - używa tego rozwiązania jako fallback dla LLMService
- **WL-79:** Integracja Jira-Cursor - może używać do zarządzania zadaniami

---

## 🚀 Plan działania - Development na MacOS, Production na Ubuntu Server

### 📍 Kontekst projektu

**Środowisko development:**
- **System:** MacOS Sonoma (MacBook Pro M1)
- **Ollama:** Zainstalowana (wersja 0.11.6), ale nieuruchomiona
- **Cel:** Utworzenie repozytorium i rozwój projektu lokalnie

**Środowisko production:**
- **System:** Ubuntu Server (PC z RTX 3060)
- **Ollama:** Do zainstalowania/konfiguracji
- **Cel:** Działający serwer LLM dla Waldus API

### 🎯 Faza 0: Setup repozytorium na MacOS (1-2 godziny) 🍎

**Cel:** Przygotowanie struktury projektu do rozwoju na MacOS i migracja Pythona z waldus-api

#### 1. Struktura repozytorium
```
ai-local-core/
├── .dev/
│   ├── scripts/
│   │   └── time.sh
│   └── logs/
│       └── cursor/
├── src/
│   ├── ollama/                  # Komunikacja z Ollama API (Python)
│   │   ├── __init__.py
│   │   ├── client.py            # Nowa klasa OllamaClient
│   │   ├── complete.py           # ollama_complete.py (przeniesiony z waldus-api)
│   │   ├── models.py            # Modele danych (Pydantic)
│   │   ├── exceptions.py        # Wyjątki
│   │   └── utils.py             # Helper functions
│   ├── image/                   # Rozpoznawanie obrazków (Python)
│   │   ├── __init__.py
│   │   ├── describe.py          # describe_image.py (przeniesiony z waldus-api)
│   │   └── models.py            # Modele BLIP
│   ├── translation/             # Tłumaczenie tekstu (Python)
│   │   ├── __init__.py
│   │   ├── translate.py         # translate_text.py (przeniesiony z waldus-api)
│   │   └── models.py            # Modele tłumaczenia
│   ├── api/                      # Flask API server (Python)
│   │   ├── __init__.py
│   │   └── server.py            # api_server.py (przeniesiony z waldus-api)
│   ├── tunnel-manager/          # Zarządzanie tunelami (Cloudflare/Tailscale) - Python
│   ├── security/                # Reverse proxy, auth, rate limiting - Python
│   └── monitoring/              # Monitoring i logowanie - Python
├── config/
│   ├── development.yaml         # Konfiguracja dla MacOS
│   ├── production.yaml          # Konfiguracja dla Ubuntu Server
│   └── models.yaml              # Lista modeli i ich konfiguracje
├── scripts/
│   ├── setup-macos.sh           # Setup na MacOS
│   ├── setup-ubuntu.sh          # Setup na Ubuntu Server
│   ├── start-ollama.sh          # Uruchomienie Ollama
│   └── deploy.sh                # Deployment na Ubuntu Server
├── docker/
│   ├── Dockerfile.ollama        # Container dla Ollama (opcjonalnie)
│   └── docker-compose.yml       # Orchestracja
├── docs/
│   └── WL-25-local-support-ollama.md
├── tests/
│   ├── unit/                    # Testy jednostkowe
│   └── integration/             # Testy integracyjne
└── README.md
```

#### 2. Różnice między MacOS (M1) a Ubuntu Server (RTX 3060)

| Aspekt | MacOS M1 (Development) | Ubuntu Server RTX 3060 (Production) |
|--------|------------------------|-------------------------------------|
| **GPU** | Apple Silicon (Metal) | NVIDIA RTX 3060 (CUDA) |
| **Wydajność** | ~10-20 tok/s (CPU/Metal) | ~30-50 tok/s (CUDA) |
| **Modele** | Mniejsze modele (3B-7B) | Większe modele (7B-13B) |
| **Cel** | Development, testy | Production, fallback API |
| **Ollama** | Lokalne testy | Publiczny dostęp przez tunnel |

#### 3. Konfiguracja środowisk

**Development (MacOS):**
- Ollama lokalnie na `localhost:11434`
- Testy z małymi modelami (Phi-3 Medium 3.8B)
- Brak tunelu (lokalne testy)
- Proste logowanie

**Production (Ubuntu Server):**
- Ollama na `localhost:11434` + reverse proxy
- Duże modele (Llama 3.1 8B Q4, Mistral 7B Q4)
- Cloudflare Tunnel lub Tailscale
- Pełne bezpieczeństwo (auth, rate limiting)
- Monitoring i alerty

### 🎯 Faza 1: Development na MacOS (2-3 godziny) ⚡

#### 1.1. Setup podstawowy
- [ ] Utworzenie struktury katalogów
- [ ] Konfiguracja `.dev/scripts/time.sh` ✅ (zrobione)
- [ ] Utworzenie `README.md` z instrukcjami
- [ ] Uruchomienie Ollama na MacOS: `ollama serve`
- [ ] Test lokalny: `curl http://localhost:11434/api/tags`

#### 1.1a. Migracja Pythona z waldus-api
- [ ] Skopiowanie plików z `waldus-api/python/` do `ai-local-core/src/`
  - [ ] `ollama_complete.py` → `src/ollama/complete.py`
  - [ ] `describe_image.py` → `src/image/describe.py`
  - [ ] `translate_text.py` → `src/translation/translate.py`
  - [ ] `api_server.py` → `src/api/server.py`
- [ ] Skopiowanie `requirements.txt` i aktualizacja
- [ ] Skopiowanie dokumentacji (README.md, INSTALLATION_COMPLETE.md, TRANSLATION_SETUP.md)
- [ ] Utworzenie `__init__.py` w każdym module
- [ ] Test kompatybilności - sprawdzenie czy skrypty działają jako CLI

#### 1.2. Pobranie modelu testowego
```bash
# Na MacOS - mały model do testów
ollama pull phi3:medium
ollama pull llama3.2:3b
```

#### 1.3. Utworzenie OllamaClient (Python) ✅
- [x] Klasa `OllamaClient` w `src/ollama/client.py` (Python) ✅
- [x] Metody: `generate()`, `chat()`, `list_models()`, `pull_model()` ✅
- [x] Obsługa błędów i retry logic ✅
- [x] Użycie biblioteki `requests` do HTTP API ✅
- [x] Kompatybilność z istniejącym `ollama_complete.py` (przeniesionym) ✅
- [x] Utworzenie `exceptions.py` z wyjątkami ✅
- [x] Utworzenie `example.py` z przykładem użycia ✅
- [ ] Refaktoryzacja `complete.py` do użycia `OllamaClient` (opcjonalnie)
- [ ] Testy jednostkowe (pytest)

#### 1.3a. Testy kompatybilności CLI ✅
- [x] Test Translation CLI - działa ✅
- [x] Test Image Description CLI - działa ✅
- [x] Test Ollama CLI - wymaga uruchomionego Ollama ⚠️
- [x] Test obsługi błędów (brak argumentów) - działa ✅
- [x] Utworzenie skryptu `scripts/test-cli.sh` ✅

#### 1.4. Konfiguracja
- [ ] `config/development.yaml` - MacOS settings
- [ ] `config/production.yaml` - Ubuntu Server settings
- [ ] Zmienne środowiskowe (.env)
- [ ] `requirements.txt` - zależności Python (requests, pydantic, pyyaml)
- [ ] `setup.py` lub `pyproject.toml` - konfiguracja pakietu Python

### 🎯 Faza 2: Testy i walidacja na MacOS (1-2 godziny) 🧪

#### 2.1. Testy funkcjonalne
- [ ] Test generowania tekstu
- [ ] Test chat completion
- [ ] Test listowania modeli
- [ ] Test obsługi błędów

#### 2.2. Testy wydajnościowe
- [ ] Pomiar tok/s na MacOS M1
- [ ] Porównanie z oczekiwaniami dla RTX 3060
- [ ] Benchmark różnych modeli

#### 2.3. Dokumentacja
- [ ] Aktualizacja `README.md`
- [ ] Dokumentacja API
- [ ] Przykłady użycia

### 🎯 Faza 3: Deployment na Ubuntu Server (3-4 godziny) 🖥️

#### 3.1. Przygotowanie serwera
- [ ] Instalacja Ollama na Ubuntu Server
- [ ] Instalacja NVIDIA drivers + CUDA
- [ ] Pobranie modeli produkcyjnych (Llama 3.1 8B Q4)
- [ ] Test lokalny na serwerze

#### 3.2. Bezpieczeństwo
- [ ] Instalacja Nginx
- [ ] Konfiguracja reverse proxy z Basic Auth
- [ ] Konfiguracja firewall (ufw)
- [ ] Rate limiting

#### 3.3. Tunnel setup
- [ ] Wybór rozwiązania (Cloudflare Tunnel / Tailscale)
- [ ] Konfiguracja Cloudflare Tunnel lub Tailscale
- [ ] Test dostępu z zewnątrz
- [ ] Konfiguracja jako systemd service

#### 3.4. Monitoring
- [ ] Logowanie requestów
- [ ] Monitoring zużycia GPU/VRAM
- [ ] Alerty (opcjonalnie)

### 🎯 Faza 4: Integracja z Waldus API (2-3 godziny) 🔗

#### 4.1. Aktualizacja waldus-api po migracji
- [ ] **Uwaga:** `OllamaProvider` już istnieje w `waldus-api/app/Providers/OllamaProvider.php`
- [ ] Aktualizacja ścieżek w `OllamaProvider.php`:
  - [ ] Zmiana `base_path('python/ollama_complete.py')` na ścieżkę do `ai-local-core/src/ollama/complete.py`
  - [ ] Możliwość konfiguracji przez zmienną środowiskową `AI_LOCAL_CORE_PATH`
- [ ] Aktualizacja `ImageDescriptionService.php`:
  - [ ] Zmiana `base_path('python/describe_image.py')` na ścieżkę do `ai-local-core/src/image/describe.py`
  - [ ] Zmiana `base_path('python/translate_text.py')` na ścieżkę do `ai-local-core/src/translation/translate.py`
- [ ] Sprawdzenie kompatybilności z nowym `OllamaClient` (Python)
- [ ] Ewentualna aktualizacja `OllamaProvider.php` do użycia nowego klienta
- [ ] Implementacja zgodna z interfejsem `LLMProvider`
- [ ] Obsługa timeoutów i retry
- [ ] Testy integracyjne - sprawdzenie czy waldus-api działa z nowymi ścieżkami

#### 4.2. FallbackService integration
- [ ] Dodanie Ollama jako fallback w `FallbackService`
- [ ] Priorytetyzacja: Anthropic → Groq → Ollama
- [ ] Test fallbacku (wyłącz Anthropic, sprawdź Ollama)

#### 4.3. Konfiguracja
- [ ] Zmienne środowiskowe dla URL Ollama
- [ ] Konfiguracja timeoutów
- [ ] Konfiguracja modeli

### 🎯 Faza 5: Optymalizacja i monitoring (opcjonalnie) 🚀

- [ ] Optymalizacja wydajności
- [ ] Monitoring kosztów energii
- [ ] Automatyczne wyłączanie GPU gdy nieużywane
- [ ] Backup konfiguracji

---

## 📋 Checklist implementacji

### MacOS (Development)
- [ ] Struktura projektu
- [ ] OllamaClient implementation
- [ ] Testy jednostkowe
- [ ] Dokumentacja
- [ ] Testy lokalne

### Ubuntu Server (Production)
- [ ] Instalacja Ollama + CUDA
- [ ] Modele produkcyjne
- [ ] Nginx reverse proxy
- [ ] Cloudflare Tunnel / Tailscale
- [ ] Monitoring

### Integracja
- [ ] OllamaProvider w Waldus API
- [ ] FallbackService integration
- [ ] Testy end-to-end
- [ ] Dokumentacja deployment

---

## 🔄 Workflow developmentu

1. **Development na MacOS:**
   - Kodowanie i testy lokalne
   - Użycie małych modeli do szybkich testów
   - Commit do repozytorium

2. **Test na Ubuntu Server:**
   - Pull kodu na serwer
   - Uruchomienie skryptów setup
   - Testy z większymi modelami

3. **Deployment:**
   - Konfiguracja tunelu
   - Integracja z Waldus API
   - Monitoring

---

## 💡 Zalecenia

1. **Rozpocznij od MacOS** - szybki development i testy
2. **Użyj małych modeli na MacOS** - szybsze iteracje
3. **Duże modele tylko na Ubuntu Server** - lepsza wydajność
4. **Cloudflare Tunnel dla szybkiego startu** - łatwa konfiguracja
5. **Tailscale dla produkcyjnego** - lepsze bezpieczeństwo

---

## 🐍 Stack technologiczny

### Język programowania: Python

**Uzasadnienie:**
- ✅ W `waldus-api` już istnieje `python/ollama_complete.py` - kompatybilność
- ✅ `OllamaProvider.php` w Waldus API wywołuje Python scripts
- ✅ `ImageDescriptionService.php` używa `describe_image.py` i `translate_text.py`
- ✅ Biblioteka `ollama` dla Pythona jest dobrze wspierana
- ✅ Łatwa integracja z istniejącym kodem
- ✅ **Plan:** Przeniesienie całego Pythona z `waldus-api/python/` do `ai-local-core/src/`

**Główne biblioteki:**
- `requests` - HTTP client do Ollama API
- `pydantic` - walidacja danych i modele
- `pyyaml` - konfiguracja YAML
- `pytest` - testy jednostkowe
- `ollama` - oficjalna biblioteka Python dla Ollama
- `torch`, `torchvision` - ML dla rozpoznawania obrazków
- `transformers` - modele ML (BLIP dla obrazków)
- `pillow` - przetwarzanie obrazów
- `flask`, `flask-cors` - API server
- `deep-translator` - tłumaczenie tekstu

**Struktura kodu (po migracji):**
```python
ai-local-core/src/
├── ollama/
│   ├── __init__.py
│   ├── client.py          # OllamaClient class (nowy)
│   ├── complete.py       # ollama_complete.py (przeniesiony)
│   ├── models.py         # Pydantic models
│   ├── exceptions.py     # Custom exceptions
│   └── utils.py          # Helper functions
├── image/
│   ├── __init__.py
│   ├── describe.py       # describe_image.py (przeniesiony)
│   └── models.py         # Modele BLIP
├── translation/
│   ├── __init__.py
│   ├── translate.py      # translate_text.py (przeniesiony)
│   └── models.py         # Modele tłumaczenia
└── api/
    ├── __init__.py
    └── server.py         # api_server.py (przeniesiony)
```

**Kompatybilność z waldus-api:**
- Nowy `OllamaClient` będzie kompatybilny z istniejącym `ollama_complete.py`
- Wszystkie skrypty będą dostępne jako CLI (zachowanie kompatybilności)
- Możliwość użycia jako zamiennik lub rozszerzenie
- Zachowanie tego samego interfejsu API

---

## 📦 Plan migracji Pythona z waldus-api

### Cel migracji

Przeniesienie całego kodu Pythona z `waldus-api/python/` do `ai-local-core/src/` w celu:
- ✅ Centralizacji wszystkich lokalnych usług ML/LLM w jednym miejscu
- ✅ Lepszej organizacji kodu
- ✅ Łatwiejszego zarządzania zależnościami
- ✅ Możliwości rozwoju ML/rozpoznawania obrazków w dedykowanym projekcie

### Pliki do przeniesienia

| Plik źródłowy (waldus-api) | Plik docelowy (ai-local-core) | Opis |
|----------------------------|-------------------------------|------|
| `python/ollama_complete.py` | `src/ollama/complete.py` | Komunikacja z Ollama API |
| `python/describe_image.py` | `src/image/describe.py` | Rozpoznawanie obrazków (BLIP) |
| `python/translate_text.py` | `src/translation/translate.py` | Tłumaczenie tekstu |
| `python/api_server.py` | `src/api/server.py` | Flask API server |
| `python/requirements.txt` | `requirements.txt` | Zależności Python |
| `python/README.md` | `docs/python-migration.md` | Dokumentacja (merge) |
| `python/INSTALLATION_COMPLETE.md` | `docs/installation.md` | Instrukcje instalacji |
| `python/TRANSLATION_SETUP.md` | `docs/translation-setup.md` | Setup tłumaczenia |
| `python/run_api.sh` | `scripts/run-api.sh` | Skrypt uruchomienia API |

### Aktualizacje w waldus-api

Po migracji należy zaktualizować ścieżki w następujących plikach:

#### 1. `app/Providers/OllamaProvider.php`
```php
// PRZED:
$scriptPath = base_path('python/ollama_complete.py');

// PO:
$aiLocalCorePath = env('AI_LOCAL_CORE_PATH', '/path/to/ai-local-core');
$scriptPath = $aiLocalCorePath . '/src/ollama/complete.py';
```

#### 2. `app/Services/ImageDescriptionService.php`
```php
// PRZED:
$this->pythonScript = base_path('python/describe_image.py');
$translateScript = base_path('python/translate_text.py');

// PO:
$aiLocalCorePath = env('AI_LOCAL_CORE_PATH', '/path/to/ai-local-core');
$this->pythonScript = $aiLocalCorePath . '/src/image/describe.py';
$translateScript = $aiLocalCorePath . '/src/translation/translate.py';
```

#### 3. Konfiguracja `.env` w waldus-api
```env
# Ścieżka do projektu ai-local-core
AI_LOCAL_CORE_PATH=/Users/piotradamczyk/Projects/Octadecimal/ai-local-core

# Alternatywnie: ścieżka bezwzględna do skryptów
OLLAMA_SCRIPT_PATH=/Users/piotradamczyk/Projects/Octadecimal/ai-local-core/src/ollama/complete.py
IMAGE_DESCRIPTION_SCRIPT_PATH=/Users/piotradamczyk/Projects/Octadecimal/ai-local-core/src/image/describe.py
TRANSLATION_SCRIPT_PATH=/Users/piotradamczyk/Projects/Octadecimal/ai-local-core/src/translation/translate.py
```

### Zachowanie kompatybilności

**Ważne:** Wszystkie przeniesione skrypty muszą zachować kompatybilność CLI:

1. **Ollama complete:**
   ```bash
   # Działa tak samo jak wcześniej
   python src/ollama/complete.py '{"user": "Hello", "temperature": 0.7}'
   ```

2. **Image description:**
   ```bash
   # Działa tak samo jak wcześniej
   python src/image/describe.py "https://example.com/image.jpg" 50
   ```

3. **Translation:**
   ```bash
   # Działa tak samo jak wcześniej
   python src/translation/translate.py "Hello world" pl
   ```

### Kolejność migracji

1. **Faza 1:** Skopiowanie plików do `ai-local-core/src/`
2. **Faza 2:** Testy kompatybilności CLI
3. **Faza 3:** Aktualizacja ścieżek w `waldus-api`
4. **Faza 4:** Testy integracyjne z `waldus-api`
5. **Faza 5:** Usunięcie starych plików z `waldus-api/python/` (opcjonalnie)

### Korzyści z migracji

- ✅ **Centralizacja:** Wszystkie lokalne usługi ML/LLM w jednym miejscu
- ✅ **Rozwój:** Łatwiejsze dodawanie nowych funkcji ML
- ✅ **Zarządzanie:** Jeden `requirements.txt`, jedna struktura projektu
- ✅ **Testy:** Łatwiejsze testowanie całego stacku ML
- ✅ **Deployment:** Możliwość deployowania jako osobny serwis

---

## 🔗 Źródła

- [Ollama Installation](https://ollama.ai/download)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Tailscale Docs](https://tailscale.com/kb/)
- [Ollama Models](https://ollama.ai/library)
- [Ollama API Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)

---

**Autor analizy:** Auto (Agent Router by Cursor)  
**Data:** 2025-11-09  
**Status:** 🟡 W toku

