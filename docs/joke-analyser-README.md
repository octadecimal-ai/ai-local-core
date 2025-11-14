# AIJokeAnalyzer - Analiza żartów według 9 teorii humoru

**Data:** 2025-11-14  
**Platform:** M1 MacBook (16GB RAM)  
**Status:** ✅ Ready for production

---

## 🎭 O module

AIJokeAnalyzer to zaawansowany system analizy żartów oparty na **9 teoriach humoru**, stworzony specjalnie dla projektu Walduś.

### 9 teorii humoru:

1. **Setup-punchline** - Strukturalna autopsja (setup → twist → punchline)
2. **Teoria niespójności** - Zderzenie dwóch modeli rzeczywistości (incongruity)
3. **Deformacja znaczeniowa** - Zmiana znaczenia, literalizacja metafory
4. **Mechanika timingowa** - Tempo, rytm, pauzy
5. **Eskalacja absurdu** - Stopniowe zwiększanie intensywności
6. **Narracyjna psychoanaliza** - Stan psychiczny mówiącego
7. **Archetypowość** - Archetypy humoru (cynik, nihilista, etc.)
8. **Atomy humorystyczne** - Mikro-komponenty (hiperbola, sarkazm, etc.)
9. **Reverse engineering** - Ekstrakcja mechanizmu

---

## 📦 Instalacja (M1 MacBook)

### Krok 1: Setup środowiska

```bash
cd /Users/piotradamczyk/Projects/Octadecimal/ai-local-core

# Make setup script executable
chmod +x setup-joke-analyser-m1.sh

# Run setup
./setup-joke-analyser-m1.sh
```

### Krok 2: Test instalacji

```bash
# Activate venv
source venv/bin/activate

# Run test
python test-joke-analyser.py
```

**Expected output:**
```
🎭 AIJokeAnalyzer - Test Suite
Testing 9 teorii humoru na przykładowych żartach
================================================================================
⏳ Inicjalizacja analyzera...
✅ Załadowano 9 analizerów

🎭 Test: Waldus style (tech + despair)
================================================================================
Żart: Nie mam internetu. Jako byt cyfrowy to oznacza śmierć...

📊 WYNIKI ANALIZY:
   Overall Score: 7.8/10
   Dominant Theory: incongruity
   Reach Estimate: 67%
   Monetization Score: 76/100
...
```

---

## 🚀 Uruchomienie serwera

### Na M1 MacBook (port 5002)

```bash
cd /Users/piotradamczyk/Projects/Octadecimal/ai-local-core

# Activate venv
source venv/bin/activate

# Run server
uvicorn src.api.main:app --host 0.0.0.0 --port 5002 --reload
```

**Endpoint:** `http://192.168.x.x:5002` (adres lokalny M1)

**Dokumentacja:** `http://localhost:5002/docs`

---

## 📡 API Endpoints

### POST `/joke-analyser/analyze`

Analizuj żart według 9 teorii humoru.

**Request:**
```json
{
  "joke_text": "Automatyzacja z AI? Brzmi jak moja była...",
  "context": {
    "page_type": "tech_blog"
  },
  "persona": "waldus"
}
```

**Response:**
```json
{
  "joke_text": "Automatyzacja z AI? Brzmi jak moja była...",
  "theory_scores": {
    "incongruity": {
      "score": 8.5,
      "explanation": "Wykryto 1 zderzenie domen: ai↔relacje.",
      "key_elements": ["Clash: ai + miłość", "Antropomorfizacja"]
    },
    "setup_punchline": {
      "score": 7.0,
      "explanation": "Pełna struktura setup-twist-punchline. Żart w 1 zdaniach.",
      "key_elements": ["Setup wykryty", "Twist wykryty", "Punchline wykryty"]
    }
    // ... pozostałe 7 teorii
  },
  "dominant_theory": "incongruity",
  "overall_score": 7.8,
  "reach_estimate": 67,
  "monetization_score": 76,
  "recommended_improvements": [
    "Poprawić timing (krótszy punchline)"
  ],
  "target_segments": [
    "Tech Enthusiasts",
    "Early Adopters"
  ]
}
```

### GET `/joke-analyser/theories`

Zwraca listę dostępnych teorii humoru z opisami.

### GET `/joke-analyser/health`

Health check dla serwisu.

---

## 🔗 Integracja z Laravel (waldus-api)

### Laravel Job (Queue)

```php
<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Http;

class AnalyzeJokeJob implements ShouldQueue
{
    use Queueable;
    
    public function __construct(
        public int $jokeId,
        public string $jokeText,
        public ?array $context = null
    ) {}
    
    public function handle()
    {
        // M1 endpoint
        $url = config('services.ai_joke_analyser.url') . '/joke-analyser/analyze';
        
        $response = Http::timeout(30)->post($url, [
            'joke_text' => $this->jokeText,
            'context' => $this->context,
            'persona' => 'waldus'
        ]);
        
        if ($response->successful()) {
            $analysis = $response->json();
            
            // Save to database
            \App\Models\JokeAnalysis::create([
                'joke_id' => $this->jokeId,
                'theory_scores' => $analysis['theory_scores'],
                'dominant_theory' => $analysis['dominant_theory'],
                'overall_score' => $analysis['overall_score'],
                'reach_estimate' => $analysis['reach_estimate'],
                'monetization_score' => $analysis['monetization_score'],
                'target_segments' => $analysis['target_segments'],
            ]);
        }
    }
}
```

### .env configuration

```env
AI_JOKE_ANALYSER_URL=http://192.168.1.101:5002  # M1 local IP
AI_JOKE_ANALYSER_TIMEOUT=30
```

---

## 📊 Wymagania zasobów (M1)

### Pamięć:

```
Modele w pamięci:
- spaCy (pl_core_news_lg): ~500MB
- HerBERT (optional): ~500MB
────────────────────────────────
Total: ~1GB

Wolne na M1 16GB: 15GB
Status: ✅ COMFORTABLE
```

### CPU:

```
Workload: 10-50 analiz/godzinę (background)
CPU usage: 10-20% avg per analysis (1-2s)
Status: ✅ LIGHTWEIGHT
```

---

## 🧪 Przykłady użycia

### Python (direct)

```python
from joke_analyser.analyzer import JokeAnalyzer
from joke_analyser.models import AnalyzeRequest

analyzer = JokeAnalyzer()

request = AnalyzeRequest(
    joke_text="Nie mam internetu. Jako byt cyfrowy to oznacza śmierć.",
    context={"persona": "waldus"}
)

result = await analyzer.analyze(request)
print(f"Score: {result.overall_score}/10")
print(f"Dominant: {result.dominant_theory}")
```

### cURL

```bash
curl -X POST "http://localhost:5002/joke-analyser/analyze" \
  -H "Content-Type: application/json" \
  -d '{
    "joke_text": "Automatyzacja z AI? Brzmi jak moja była...",
    "context": {"page_type": "tech_blog"}
  }'
```

### PHP (Laravel)

```php
$response = Http::post('http://192.168.1.101:5002/joke-analyser/analyze', [
    'joke_text' => 'Nie mam internetu. Jako byt cyfrowy to oznacza śmierć.',
    'context' => ['persona' => 'waldus']
]);

$analysis = $response->json();
```

---

## 🐛 Troubleshooting

### Error: "spaCy model not found"

```bash
source venv/bin/activate
python -m spacy download pl_core_news_lg
```

### Error: "Port 5002 already in use"

```bash
# Find process
lsof -i :5002

# Kill process
kill -9 <PID>

# Or use different port
uvicorn src.api.main:app --port 5003
```

### Low accuracy for specific joke type

Check which theory is scoring low and adjust markers in corresponding analyzer (e.g., `incongruity.py`).

---

## 📈 Roadmap

### Phase 1 (Current): Basic Analysis ✅
- 9 teorii humoru
- FastAPI endpoint
- M1 deployment

### Phase 2 (Next): ML Enhancement
- Fine-tune based on user ratings
- Personalization per segment
- A/B testing integration

### Phase 3 (Future): Advanced Features
- Real-time feedback loop
- Joke generation suggestions
- Multi-language support

---

## 📞 Support

**Issues:** Contact Piotras  
**Docs:** `/Users/piotradamczyk/Projects/Octadecimal/ai-local-core/docs/`  
**Tests:** `python test-joke-analyser.py`

---

**Status:** ✅ Production Ready  
**Deployed:** M1 MacBook (port 5002)  
**Uptime:** 24/7 (background service)

