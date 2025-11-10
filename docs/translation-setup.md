# Setup tłumaczenia opisów obrazków (OPUS-MT)

## Instalacja

### 1. Zainstaluj zależności (jeśli jeszcze nie zainstalowane)

```bash
cd python
source venv/bin/activate
pip install transformers torch
```

### 2. Test instalacji

```bash
python3 translate_text.py "A cat sitting on a chair" pl
```

Powinno zwrócić JSON:
```json
{
  "success": true,
  "original": "A cat sitting on a chair",
  "translated": "Kot siedzący na krześle",
  "source_language": "en",
  "target_language": "pl"
}
```

## Obsługiwane języki

- `pl` - Polski (Helsinki-NLP/opus-mt-en-pl)
- `de` - Niemiecki (Helsinki-NLP/opus-mt-en-de)
- `fr` - Francuski (Helsinki-NLP/opus-mt-en-fr)
- `es` - Hiszpański (Helsinki-NLP/opus-mt-en-es)
- `it` - Włoski (Helsinki-NLP/opus-mt-en-it)

## Pierwsze użycie

Przy pierwszym użyciu model zostanie automatycznie pobrany z Hugging Face (~300-500 MB).
Następne użycia będą szybsze, ponieważ model będzie w cache.

## Konfiguracja Laravel

W `.env` ustaw:

```env
IMAGE_DESCRIPTION_LANGUAGE=pl
IMAGE_DESCRIPTION_TRANSLATE=true
```

## Jak to działa

1. BLIP generuje opis obrazka po angielsku
2. Jeśli `language !== 'en'` i `translate_enabled === true`:
   - Wywołuje `translate_text.py` z angielskim opisem
   - OPUS-MT tłumaczy na wybrany język
   - Zwraca przetłumaczony opis
3. Jeśli tłumaczenie się nie powiedzie → zwraca angielski opis jako fallback

## Rozmiar modelu

- **OPUS-MT EN-PL**: ~300-500 MB
- **Cache**: ~500 MB (po pierwszym pobraniu)
- **RAM podczas użycia**: ~1-2 GB

## Optymalizacja

Dla szybszego działania można użyć GPU:
```bash
export DEVICE_ID=0  # Użyj GPU jeśli dostępne
```

Lub w Python:
```python
# translate_text.py automatycznie wykrywa CUDA jeśli dostępne
```

