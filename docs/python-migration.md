# Image Description Service (Python)

Service do opisywania obrazów używający modelu BLIP (Bootstrapping Language-Image Pre-training).

## Instalacja

### 1. Zainstaluj zależności Python

```bash
cd python
pip install -r requirements.txt
```

Lub użyj virtual environment (zalecane):

```bash
cd python
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# lub
venv\Scripts\activate  # Windows

pip install -r requirements.txt
```

### 2. Pobierz model BLIP

Model zostanie automatycznie pobrany przy pierwszym użyciu przez bibliotekę `transformers`.

Alternatywnie możesz wstępnie pobrać model:

```bash
python3 -c "from transformers import BlipProcessor, BlipForConditionalGeneration; \
BlipProcessor.from_pretrained('Salesforce/blip-image-captioning-base'); \
BlipForConditionalGeneration.from_pretrained('Salesforce/blip-image-captioning-base')"
```

## Użycie

### Tryb CLI (direct)

Uruchom bezpośrednio przez command line:

```bash
python3 describe_image.py "https://example.com/image.jpg" 50
```

Parametry:
- `image_url` - URL obrazu do opisania
- `max_length` - (opcjonalne) maksymalna długość opisu (domyślnie 50)

Wynik (JSON):
```json
{
  "success": true,
  "description": "a cat sitting on a chair",
  "image_url": "https://example.com/image.jpg"
}
```

### Tryb API (Flask server)

Uruchom API server:

```bash
python3 api_server.py
```

Server będzie dostępny na `http://127.0.0.1:5001`

Możesz zmienić port przez zmienną środowiskową:
```bash
PORT=5002 python3 api_server.py
```

#### API Endpoints

**Health Check:**
```bash
curl http://127.0.0.1:5001/health
```

**Describe Image:**
```bash
curl -X POST http://127.0.0.1:5001/describe \
  -H "Content-Type: application/json" \
  -d '{
    "image_url": "https://example.com/image.jpg",
    "max_length": 50
  }'
```

Response:
```json
{
  "success": true,
  "description": "a cat sitting on a chair",
  "image_url": "https://example.com/image.jpg"
}
```

## Konfiguracja

### Zmienne środowiskowe

- `BLIP_MODEL` - Nazwa modelu do użycia (domyślnie: `Salesforce/blip-image-captioning-base`)
- `DEVICE` - Urządzenie (`cpu` lub `cuda`) - domyślnie `cpu`
- `PORT` - Port dla API server (domyślnie: `5001`)
- `HOST` - Host dla API server (domyślnie: `127.0.0.1`)

### Używanie GPU (opcjonalnie)

Jeśli masz dostęp do CUDA GPU, zainstaluj PyTorch z obsługą CUDA:

```bash
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
```

Następnie ustaw:
```bash
export DEVICE=cuda
python3 api_server.py
```

## Wydajność

- **CPU:** ~2-5 sekund na obraz
- **GPU:** ~0.5-1 sekunda na obraz

## Wymagania systemowe

- Python 3.8+
- ~2-4GB RAM dla modelu BLIP base
- ~500MB miejsca na dysku dla modelu

## Integracja z Laravel

Service jest automatycznie integrowany przez `ImageDescriptionService` w Laravel.

W `.env` możesz skonfigurować:

```env
IMAGE_DESCRIPTION_MODE=cli  # lub 'api'
IMAGE_DESCRIPTION_PYTHON_PATH=python3
IMAGE_DESCRIPTION_API_URL=http://127.0.0.1:5001
```

## Troubleshooting

### Problem: Model nie ładuje się

Sprawdź czy masz wystarczająco miejsca na dysku i pamięci RAM. Model BLIP base wymaga ~500MB miejsca.

### Problem: Wolne przetwarzanie

- Użyj GPU jeśli dostępne (`DEVICE=cuda`)
- Rozważ użycie mniejszego modelu
- Użyj trybu API zamiast CLI dla lepszej wydajności (model ładuje się raz)

### Problem: Błąd podczas pobierania obrazu

- Sprawdź czy URL jest dostępny publicznie
- Sprawdź czy obraz nie jest zbyt duży
- Zwiększ timeout w kodzie jeśli potrzeba

