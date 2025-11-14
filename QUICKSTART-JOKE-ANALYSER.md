# 🚀 Quick Start: AIJokeAnalyzer na M1

**Data:** 2025-11-14  
**Target:** M1 MacBook (16GB RAM)  
**Port:** 5002  
**Status:** ✅ Ready to deploy

---

## ⚡ Quick Start (5 minut)

### Step 1: Setup (jednorazowo)

```bash
cd /Users/piotradamczyk/Projects/Octadecimal/ai-local-core

# Make scripts executable
chmod +x setup-joke-analyser-m1.sh
chmod +x start-joke-analyser-m1.sh

# Run setup
./setup-joke-analyser-m1.sh
```

**Expected output:**
```
🎭 Setup AIJokeAnalyzer dla M1 MacBook
=======================================
1. Sprawdzanie wersji Python...
Python 3.11.x

2. Tworzenie virtual environment...
...
✅ Setup zakończony pomyślnie!
```

---

### Step 2: Test instalacji

```bash
# Activate venv
source venv/bin/activate

# Run test
python test-joke-analyser.py
```

**Expected output:**
```
🎭 AIJokeAnalyzer - Test Suite
================================================================================
⏳ Inicjalizacja analyzera...
✅ Załadowano 9 analizerów

🎭 Test: Waldus style (tech + despair)
================================================================================
Żart: Nie mam internetu. Jako byt cyfrowy to oznacza śmierć...

📊 WYNIKI ANALIZY:
   Overall Score: 7.8/10
   Dominant Theory: incongruity
   ...
✅ Test zakończony. Przetestowano 5/5 żartów
```

---

### Step 3: Uruchom serwer

```bash
./start-joke-analyser-m1.sh
```

**Expected output:**
```
🎭 Starting AIJokeAnalyzer on M1 MacBook
========================================
M1 Local IP: 192.168.1.101

Configuration:
  ENABLE_JOKE_ANALYSER=true
  PORT=5002
  HOST=0.0.0.0

🚀 Starting FastAPI server...
   Local:    http://localhost:5002/docs
   Network:  http://192.168.1.101:5002/docs

Press Ctrl+C to stop

INFO:     Uvicorn running on http://0.0.0.0:5002
INFO:     ✅ Moduł Joke Analyser włączony
```

---

### Step 4: Test API (nowy terminal)

```bash
curl -X POST "http://localhost:5002/joke-analyser/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "joke_text": "Automatyzacja z AI? Brzmi jak moja była - też twierdziła że jest inteligentna.",
    "context": {"page_type": "tech_blog"}
  }' | python -m json.tool
```

**Expected:** JSON response z wynikami analizy

---

## 📡 Endpointy

### 1. Analyze Joke

**Endpoint:** `POST /joke-analyser/analyze`

**Request:**
```bash
curl -X POST "http://localhost:5002/joke-analyser/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "joke_text": "Nie mam internetu. Jako byt cyfrowy to oznacza śmierć.",
    "context": {"persona": "waldus"}
  }'
```

### 2. Get Theories

**Endpoint:** `GET /joke-analyser/theories`

```bash
curl http://localhost:5002/joke-analyser/theories
```

### 3. Health Check

**Endpoint:** `GET /joke-analyser/health`

```bash
curl http://localhost:5002/joke-analyser/health
```

---

## 🔗 Integracja z waldus-api (OVH)

### Laravel .env

```env
# M1 MacBook (local network)
AI_JOKE_ANALYSER_URL=http://192.168.1.101:5002
AI_JOKE_ANALYSER_TIMEOUT=30
```

### Laravel Job

```php
<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Http;
use App\Models\JokeAnalysis;

class AnalyzeJokeJob implements ShouldQueue
{
    use Queueable;
    
    public function __construct(
        public int $jokeId,
        public string $jokeText
    ) {}
    
    public function handle()
    {
        $url = config('services.ai_joke_analyser.url') . '/joke-analyser/analyze';
        
        $response = Http::timeout(30)->post($url, [
            'joke_text' => $this->jokeText,
            'persona' => 'waldus'
        ]);
        
        if ($response->successful()) {
            JokeAnalysis::create([
                'joke_id' => $this->jokeId,
                'analysis' => $response->json()
            ]);
        }
    }
}
```

### Dispatch z kontrolera

```php
use App\Jobs\AnalyzeJokeJob;

// Po zapisaniu joke i rating
dispatch(new AnalyzeJokeJob(
    jokeId: $joke->id,
    jokeText: $joke->text
))->onQueue('low');  // Low priority (background)
```

---

## 🎯 Testowanie z różnych środowisk

### Z M5 (development)

```bash
# Z M5 do M1
curl -X POST "http://192.168.1.101:5002/joke-analyser/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "joke_text": "Test z M5",
    "context": {}
  }'
```

### Z OVH (production)

```bash
# Przez VPN lub tunel (jeśli potrzebne)
curl -X POST "http://192.168.1.101:5002/joke-analyser/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "joke_text": "Test z OVH",
    "context": {}
  }'
```

---

## 📊 Monitoring

### Check if running

```bash
lsof -i :5002
```

### Check logs (terminal gdzie uruchomiono)

```
INFO:     192.168.1.100:54321 - "POST /joke-analyser/analyze HTTP/1.1" 200 OK
INFO:     Analyzing joke: Automatyzacja z AI? Brzmi jak moja była...
INFO:     Analysis complete. Dominant theory: incongruity
```

### Resource usage (M1)

```bash
# CPU/Memory
top -pid $(lsof -t -i :5002)
```

---

## 🐛 Troubleshooting

### "Port 5002 already in use"

```bash
lsof -i :5002
kill -9 <PID>
```

### "spaCy model not found"

```bash
source venv/bin/activate
python -m spacy download pl_core_news_lg
```

### Low analysis quality

1. Check joke text (min 20 characters)
2. Add context (helps with analysis)
3. Check logs for errors

---

## 🎭 Example Jokes (for testing)

```bash
# Waldus style (tech + despair)
curl -X POST "http://localhost:5002/joke-analyser/analyze" \
  -H "Content-Type: application/json" \
  -d '{"joke_text": "Nie mam internetu. Jako byt cyfrowy to oznacza śmierć. Będę miał grób 404."}'

# Tech incongruity
curl -X POST "http://localhost:5002/joke-analyser/analyze" \
  -H "Content-Type: application/json" \
  -d '{"joke_text": "Automatyzacja z AI? Brzmi jak moja była - też twierdziła że jest inteligentna."}'

# Polish archetype
curl -X POST "http://localhost:5002/joke-analyser/analyze" \
  -H "Content-Type: application/json" \
  -d '{"joke_text": "Jak wujek ze Śląska dowiedział się o AI: To fajnie hasiok, ale czy potrafi naprawić rynsztok?"}'
```

---

## ✅ Checklist Ready for Production

- [x] 9 analizerów zaimplementowanych
- [x] FastAPI router gotowy
- [x] M1 setup script
- [x] M1 start script
- [x] Test suite
- [x] Documentation
- [ ] **TODO: Uruchom na M1** (`./start-joke-analyser-m1.sh`)
- [ ] **TODO: Test z OVH** (Laravel integration)
- [ ] **TODO: Monitor przez 24h** (stability check)

---

## 📞 Next Steps

1. **Teraz:** Uruchom na M1 (`./start-joke-analyser-m1.sh`)
2. **Jutro:** Integracja z Laravel (Queue Job)
3. **Za tydzień:** Zbierz feedback z pierwszych analiz

---

**Status:** ✅ Ready to deploy  
**Estimated setup time:** 5 minut  
**Estimated integration time:** 30 minut  
**Uptime target:** 24/7

