# 🧪 Test Bielik z Promptami dla 9 Teorii Humoru

Skrypt do testowania promptów na żartach Waldusia używając Bielik przez Ollama.

## 📋 Wymagania

1. **Ollama zainstalowany i uruchomiony:**
   ```bash
   ollama serve
   ```

2. **Model Bielik zainstalowany:**
   ```bash
   ollama pull bielik-7b
   ```

3. **Plik z żartami:**
   - `validation/test-waldus-classics.json`

## 🚀 Użycie

### Podstawowe (pierwszy żart, wszystkie 9 teorii):
```bash
python3 test-bielik-prompts.py
```

### Konkretny żart:
```bash
python3 test-bielik-prompts.py --joke-id 1
```

### Wszystkie żarty:
```bash
python3 test-bielik-prompts.py --all
```

### Tylko jedna teoria:
```bash
python3 test-bielik-prompts.py --theory setup_punchline
```

### Inny model:
```bash
python3 test-bielik-prompts.py --model llama3.1:8b
```

### Inny URL Ollama:
```bash
python3 test-bielik-prompts.py --base-url http://192.168.1.100:11434
```

## 📊 Co skrypt robi:

1. **Ładuje żarty** z `validation/test-waldus-classics.json`
2. **Dla każdego żartu i każdej teorii:**
   - Wysyła prompt do Bielik przez Ollama
   - Parsuje JSON response
   - Pokazuje szczegółowe logi:
     - Wysłany prompt
     - Raw response z modelu
     - Sparsowany JSON
     - Wyniki analizy (co model znalazł, dlaczego tak ocenił)
3. **Zapisuje wyniki** do `test-bielik-results-YYYYMMDD_HHMMSS.json`

## 📝 Format Outputu

Dla każdej teorii skrypt pokazuje:
- **SETUP/PUNCHLINE:** setup, oczekiwanie, zwrot, punchline, dlaczego działa
- **INCONGRUITY:** typ niespójności, ramy, jakość rozwiązania, czynnik zaskoczenia
- **SEMANTIC_SHIFT:** przesunięte słowo, oryginalne/nowe znaczenie, typ przesunięcia
- **TIMING:** tempo, długości zdań, wariacja rytmu, skuteczność pauz
- **ABSURD_ESCALATION:** początkowy absurd, eskalacja, załamania logiczne
- **PSYCHOANALYSIS:** mechanizm psychologiczny, postaci, łuk emocjonalny
- **ARCHETYPE:** archetypy, markery kulturowe, rezonans kulturowy
- **HUMOR_ATOMS:** znalezione atomy, gęstość, jakość, kompozycja
- **REVERSE_ENGINEERING:** rdzenny mechanizm, wzorzec strukturalny, replikowalność

## 📁 Plik Wyników

JSON z wynikami zawiera:
- `joke_id`, `joke_text`
- `results[]` - dla każdej teorii:
  - `theory` - nazwa teorii
  - `success` - czy parsowanie się udało
  - `analysis` - sparsowany JSON z analizy
  - `raw_response` - surowa odpowiedź z modelu
  - `elapsed_ms` - czas analizy
- `stats` - statystyki (udane/nieudane, średni czas)

## ⚠️ Uwagi

- Skrypt dodaje 2s pauzy między requestami (żeby nie przeciążać Ollama)
- Dla wszystkich żartów + wszystkie teorie może to zająć dużo czasu
- Sprawdź czy Ollama działa: `curl http://localhost:11434/api/tags`
