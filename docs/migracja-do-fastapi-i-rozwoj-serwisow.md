# Migracja do FastAPI i rozwój serwisów AI

**Data utworzenia:** 2025-11-13 18:12:26  
**Dla:** Cursor AI Assistant pracującego w projekcie `ai-local-core`  
**Cel:** Kompleksowa instrukcja migracji z Flask do FastAPI oraz rozwoju nowych serwisów (ai-joker, ai-joke-analyser)

---

## 📋 SPIS TREŚCI

1. [Przygotowanie środowiska](#1-przygotowanie-środowiska)
2. [Migracja z Flask do FastAPI](#2-migracja-z-flask-do-fastapi)
3. [Instalacja komponentów](#3-instalacja-komponentów)
4. [Architektura modularna](#4-architektura-modularna)
5. [Rozwój serwisu ai-joker](#5-rozwój-serwisu-ai-joker)
6. [Rozwój serwisu ai-joke-analyser](#6-rozwój-serwisu-ai-joke-analyser)
7. [Konfiguracja środowiskowa](#7-konfiguracja-środowiskowa)
8. [Testowanie](#8-testowanie)
9. [Deployment](#9-deployment)

---

## 1. PRZYGOTOWANIE ŚRODOWISKA

### 1.1. Wymagania wstępne

- Python 3.10+ (sprawdź: `python3 --version`)
- Virtual environment (venv) - już istnieje w projekcie
- Dostęp do GPU (opcjonalnie, dla Bielik 7B)
- Dostęp do Ollama (dla istniejących serwisów)

### 1.2. Aktywacja środowiska wirtualnego

```bash
cd /Users/piotradamczyk/Projects/Octadecimal/ai-local-core
source venv/bin/activate  # Linux/Mac
# lub
venv\Scripts\activate  # Windows
```

### 1.3. Backup istniejącego kodu - niepotrzebne - pomijamy

**WAŻNE:** Przed rozpoczęciem migracji wykonaj backup:

```bash
# Utwórz branch dla migracji
git checkout -b feature/migracja-fastapi

# Lub skopiuj istniejący server.py
cp src/api/server.py src/api/server.py.flask-backup
```

---

## 2. MIGRACJA Z FLASK DO FASTAPI

### 2.1. Aktualizacja requirements.txt

Dodaj FastAPI i zależności do `requirements.txt`:

```txt
# Istniejące zależności
torch>=2.0.0
torchvision>=0.15.0
transformers>=4.30.0
pillow>=9.5.0
requests>=2.31.0
deep-translator>=1.11.4
ollama>=0.3.0

# FastAPI i zależności
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
pydantic>=2.5.0
pydantic-settings>=2.1.0
python-multipart>=0.0.6

# Opcjonalnie (dla lepszej dokumentacji)
python-jose[cryptography]>=3.3.0
```

**Instalacja:**

```bash
pip install -r requirements.txt
```

### 2.2. Struktura katalogów (nowa)

Utwórz modularną strukturę:

```
src/
├── api/
│   ├── __init__.py
│   ├── main.py              # Główny plik FastAPI (nowy)
│   ├── config.py             # Konfiguracja (nowy)
│   ├── dependencies.py       # Zależności (nowy)
│   └── server.py             # Flask (stary, do usunięcia po migracji)
│
├── modules/
│   ├── __init__.py
│   ├── image/
│   │   ├── __init__.py
│   │   ├── router.py         # Router FastAPI dla obrazków
│   │   └── service.py         # Logika biznesowa
│   │
│   ├── ollama/
│   │   ├── __init__.py
│   │   ├── router.py         # Router FastAPI dla Ollama
│   │   └── service.py         # Logika biznesowa
│   │
│   ├── joker/                # NOWY MODUŁ
│   │   ├── __init__.py
│   │   ├── router.py
│   │   ├── service.py
│   │   └── models.py          # Modele Pydantic
│   │
│   └── joke_analyser/        # NOWY MODUŁ
│       ├── __init__.py
│       ├── router.py
│       ├── service.py
│       └── models.py
│
├── image/                    # Istniejące (do refaktoryzacji)
├── ollama/                   # Istniejące (do refaktoryzacji)
├── translation/              # Istniejące
└── polling/                  # Istniejące
```

**Utworzenie struktury:**

```bash
mkdir -p src/modules/{image,ollama,joker,joke_analyser}
touch src/modules/__init__.py
touch src/modules/image/{__init__.py,router.py,service.py}
touch src/modules/ollama/{__init__.py,router.py,service.py}
touch src/modules/joker/{__init__.py,router.py,service.py,models.py}
touch src/modules/joke_analyser/{__init__.py,router.py,service.py,models.py}
touch src/api/{main.py,config.py,dependencies.py}
```

### 2.3. Konfiguracja (config.py)

Utwórz `src/api/config.py`:

```python
"""
Konfiguracja aplikacji FastAPI
Wspiera modularną architekturę z możliwością włączania/wyłączania modułów
"""

from pydantic_settings import BaseSettings
from typing import Optional


class ServiceConfig(BaseSettings):
    """Konfiguracja serwisu"""
    
    # Podstawowe ustawienia
    SERVICE_NAME: str = "ai-local-core"
    HOST: str = "127.0.0.1"
    PORT: int = 5001
    DEBUG: bool = False
    
    # Włączanie/wyłączanie modułów
    ENABLE_IMAGE_DESCRIPTION: bool = True
    ENABLE_OLLAMA: bool = True
    ENABLE_JOKER: bool = False
    ENABLE_JOKE_ANALYSER: bool = False
    
    # Konfiguracja modułów
    # Image Description
    IMAGE_MODEL_NAME: str = "Salesforce/blip-image-captioning-base"
    
    # Ollama
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_DEFAULT_MODEL: str = "llama2"
    
    # Joker (Bielik 7B)
    JOKER_MODEL_PATH: Optional[str] = None  # Ścieżka do modelu lokalnego
    JOKER_MODEL_NAME: str = "bielik-7b-v0.1"
    JOKER_USE_GPU: bool = True
    JOKER_QUANTIZATION: str = "int8"  # int4, int8, fp16
    
    # Joke Analyser
    JOKE_ANALYSER_MODEL_NAME: str = "allegro/herbert-base-cased"
    JOKE_ANALYSER_USE_GPU: bool = False  # CPU wystarczy
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


# Globalna instancja konfiguracji
config = ServiceConfig()
```

### 2.4. Główny plik FastAPI (main.py)

Utwórz `src/api/main.py`:

```python
#!/usr/bin/env python3
"""
FastAPI server dla ai-local-core
Modularna architektura z możliwością włączania/wyłączania modułów
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging
import sys
import os

# Dodaj ścieżkę do src do PYTHONPATH
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from api.config import config
from api.dependencies import get_logger

# Setup logging
logging.basicConfig(
    level=logging.INFO if not config.DEBUG else logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = get_logger(__name__)

# Inicjalizacja FastAPI
app = FastAPI(
    title=config.SERVICE_NAME,
    description="Lokalne serwisy AI dla Waldus API",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # W produkcji ograniczyć do konkretnych domen
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check
@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": config.SERVICE_NAME,
        "version": "2.0.0"
    }


# Warunkowe włączanie modułów
if config.ENABLE_IMAGE_DESCRIPTION:
    try:
        from modules.image.router import router as image_router
        app.include_router(image_router, prefix="/describe", tags=["Image"])
        logger.info("✅ Moduł Image Description włączony")
    except Exception as e:
        logger.error(f"❌ Błąd włączania modułu Image Description: {e}")

if config.ENABLE_OLLAMA:
    try:
        from modules.ollama.router import router as ollama_router
        app.include_router(ollama_router, prefix="/ollama", tags=["Ollama"])
        logger.info("✅ Moduł Ollama włączony")
    except Exception as e:
        logger.error(f"❌ Błąd włączania modułu Ollama: {e}")

if config.ENABLE_JOKER:
    try:
        from modules.joker.router import router as joker_router
        app.include_router(joker_router, prefix="/joker", tags=["Joker"])
        logger.info("✅ Moduł Joker włączony")
    except Exception as e:
        logger.error(f"❌ Błąd włączania modułu Joker: {e}")

if config.ENABLE_JOKE_ANALYSER:
    try:
        from modules.joke_analyser.router import router as analyser_router
        app.include_router(analyser_router, prefix="/joke-analyser", tags=["Joke Analyser"])
        logger.info("✅ Moduł Joke Analyser włączony")
    except Exception as e:
        logger.error(f"❌ Błąd włączania modułu Joke Analyser: {e}")


# Globalny handler błędów
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Nieoczekiwany błąd: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": "Wewnętrzny błąd serwera",
            "detail": str(exc) if config.DEBUG else None
        }
    )


if __name__ == "__main__":
    import uvicorn
    logger.info(f"🚀 Uruchamianie {config.SERVICE_NAME} na {config.HOST}:{config.PORT}")
    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.DEBUG,
        log_level="info"
    )
```

### 2.5. Zależności (dependencies.py)

Utwórz `src/api/dependencies.py`:

```python
"""
Zależności FastAPI (dependency injection)
"""

import logging
from functools import lru_cache


@lru_cache()
def get_logger(name: str) -> logging.Logger:
    """Zwraca logger dla danego modułu"""
    return logging.getLogger(name)
```

### 2.6. Migracja istniejących endpointów

#### 2.6.1. Image Description Router

Utwórz `src/modules/image/router.py`:

```python
"""
Router FastAPI dla opisu obrazków
Migracja z Flask: /describe
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, HttpUrl
from typing import Optional
import logging

from api.config import config
from api.dependencies import get_logger
from image.describe import describe_image, load_model

logger = get_logger(__name__)
router = APIRouter()

# Załaduj model przy starcie
logger.info("Inicjalizacja modułu Image Description...")
try:
    load_model()
    logger.info("✅ Moduł Image Description gotowy")
except Exception as e:
    logger.error(f"❌ Błąd inicjalizacji modułu Image Description: {e}")


class ImageDescriptionRequest(BaseModel):
    """Request model dla opisu obrazka"""
    image_url: HttpUrl
    max_length: Optional[int] = 50


class ImageDescriptionResponse(BaseModel):
    """Response model dla opisu obrazka"""
    success: bool
    description: Optional[str] = None
    image_url: str
    error: Optional[str] = None


@router.post("/", response_model=ImageDescriptionResponse)
async def describe(
    request: ImageDescriptionRequest,
    logger: logging.Logger = Depends(get_logger)
):
    """
    Opisz obrazek
    
    - **image_url**: URL obrazka do opisu
    - **max_length**: Maksymalna długość opisu (domyślnie 50)
    """
    try:
        logger.info(f"Opisywanie obrazka: {request.image_url}")
        description = describe_image(str(request.image_url), request.max_length)
        
        return ImageDescriptionResponse(
            success=True,
            description=description,
            image_url=str(request.image_url)
        )
    except Exception as e:
        logger.error(f"Błąd opisywania obrazka: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Błąd opisywania obrazka: {str(e)}"
        )
```

#### 2.6.2. Ollama Router

Utwórz `src/modules/ollama/router.py`:

```python
"""
Router FastAPI dla Ollama
Migracja z Flask: /ollama/chat
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
import logging

from api.config import config
from api.dependencies import get_logger
from ollama.client import OllamaClient

logger = get_logger(__name__)
router = APIRouter()

# Inicjalizacja klienta Ollama
ollama_client = OllamaClient()


class OllamaChatRequest(BaseModel):
    """Request model dla chat Ollama"""
    user: str
    system: Optional[str] = None
    task: Optional[str] = None
    model: Optional[str] = None
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = 1000


class OllamaChatResponse(BaseModel):
    """Response model dla chat Ollama"""
    success: bool
    response: Optional[str] = None
    usage: Optional[dict] = None
    model: Optional[str] = None
    error: Optional[str] = None


@router.post("/chat", response_model=OllamaChatResponse)
async def chat(
    request: OllamaChatRequest,
    logger: logging.Logger = Depends(get_logger)
):
    """
    Wykonaj zapytanie do Ollama z przekazanym promptem
    
    - **user**: Wiadomość użytkownika (wymagane)
    - **system**: Opcjonalny system prompt
    - **task**: Opcjonalne dodatkowe instrukcje
    - **model**: Opcjonalna nazwa modelu
    - **temperature**: Temperatura (domyślnie 0.7)
    - **max_tokens**: Maksymalna liczba tokenów (domyślnie 1000)
    """
    try:
        user_message = request.user
        if request.task:
            user_message = f"{user_message}\n\nZADANIE:\n{request.task}"
        
        logger.info(f"Wysyłanie zapytania do Ollama (model={request.model or ollama_client.default_model})")
        result = ollama_client.chat(
            user=user_message,
            system=request.system,
            model=request.model,
            temperature=request.temperature,
            max_tokens=request.max_tokens
        )
        
        return OllamaChatResponse(
            success=True,
            response=result['text'],
            usage=result['usage'],
            model=result['raw'].get('model', request.model or ollama_client.default_model)
        )
    except ValueError as e:
        logger.error(f"Błąd walidacji zapytania do Ollama: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Błąd podczas komunikacji z Ollama: {e}")
        raise HTTPException(status_code=500, detail=str(e))
```

---

## 3. INSTALACJA KOMPONENTÓW

### 3.1. Zależności Python

```bash
# Zainstaluj wszystkie zależności
pip install -r requirements.txt

# Sprawdź instalację FastAPI
python -c "import fastapi; print(fastapi.__version__)"
```

### 3.2. Bielik 7B (dla ai-joker)

**Opcja A: MLX (Mac M1/M5) - REKOMENDOWANE**

```bash
# Instalacja MLX
pip install mlx mlx-lm

# Pobranie modelu Bielik 7B
python -c "
from mlx_lm import load, generate
model, tokenizer = load('piotradamczyk/bielik-7b-v0.1')
"
```

**Opcja B: llama.cpp (Mac/Ubuntu)**

```bash
# Instalacja llama.cpp
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
make

# Pobranie modelu (GGUF format)
# Instrukcje: https://huggingface.co/piotradamczyk/bielik-7b-v0.1
```

**Opcja C: Transformers (Ubuntu z GPU)**

```bash
# Zainstaluj transformers (już jest w requirements.txt)
# Model zostanie pobrany automatycznie przy pierwszym użyciu
```

### 3.3. HerBERT (dla ai-joke-analyser)

```bash
# HerBERT jest już dostępny przez transformers
# Pobierze się automatycznie przy pierwszym użyciu

# Sprawdź instalację
python -c "
from transformers import AutoTokenizer, AutoModel
tokenizer = AutoTokenizer.from_pretrained('allegro/herbert-base-cased')
print('✅ HerBERT zainstalowany')
"
```

### 3.4. spaCy (dla ai-joke-analyser)

```bash
# Instalacja spaCy
pip install spacy

# Pobranie modelu polskiego
python -m spacy download pl_core_news_sm

# Sprawdź instalację
python -c "import spacy; nlp = spacy.load('pl_core_news_sm'); print('✅ spaCy PL zainstalowany')"
```

---

## 4. ARCHITEKTURA MODULARNA

### 4.1. Koncepcja

FastAPI pozwala na **modularną architekturę**, gdzie każdy serwis jest osobnym routerem:

```
FastAPI App (main.py)
├── /describe (Image Description) - warunkowo włączony
├── /ollama (Ollama) - warunkowo włączony
├── /joker (Joker) - warunkowo włączony
└── /joke-analyser (Joke Analyser) - warunkowo włączony
```

### 4.2. Wzorzec routera

Każdy moduł powinien mieć:

1. **router.py** - Endpointy FastAPI
2. **service.py** - Logika biznesowa
3. **models.py** - Modele Pydantic (request/response)

**Przykład struktury:**

```python
# modules/joker/router.py
from fastapi import APIRouter, Depends
from .service import JokerService
from .models import JokeRequest, JokeResponse

router = APIRouter()
service = JokerService()

@router.post("/generate", response_model=JokeResponse)
async def generate_joke(request: JokeRequest):
    return await service.generate(request)
```

---

## 5. ROZWÓJ SERWISU AI-JOKER

### 5.1. Modele Pydantic

Utwórz `src/modules/joker/models.py`:

```python
"""
Modele Pydantic dla serwisu Joker
"""

from pydantic import BaseModel, Field
from typing import Optional, List


class JokeRequest(BaseModel):
    """Request model dla generowania żartu"""
    topic: Optional[str] = Field(None, description="Temat żartu")
    style: Optional[str] = Field("sarcastic", description="Styl żartu (sarcastic, witty, absurd)")
    length: Optional[str] = Field("medium", description="Długość (short, medium, long)")
    temperature: Optional[float] = Field(0.8, ge=0.0, le=2.0, description="Temperatura generowania")
    max_tokens: Optional[int] = Field(200, ge=50, le=500, description="Maksymalna liczba tokenów")


class JokeResponse(BaseModel):
    """Response model dla wygenerowanego żartu"""
    success: bool
    joke: Optional[str] = None
    topic: Optional[str] = None
    style: Optional[str] = None
    generation_time: Optional[float] = None
    model: Optional[str] = None
    error: Optional[str] = None
```

### 5.2. Serwis (service.py)

Utwórz `src/modules/joker/service.py`:

```python
"""
Serwis generowania żartów używający Bielik 7B
"""

import time
import logging
from typing import Optional
from .models import JokeRequest, JokeResponse
from api.config import config

logger = logging.getLogger(__name__)


class JokerService:
    """Serwis generowania żartów"""
    
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self._load_model()
    
    def _load_model(self):
        """Załaduj model Bielik 7B"""
        try:
            logger.info(f"Ładowanie modelu Bielik: {config.JOKER_MODEL_NAME}")
            
            # Opcja A: MLX (Mac)
            if config.JOKER_USE_GPU and hasattr(config, 'USE_MLX'):
                from mlx_lm import load
                self.model, self.tokenizer = load(config.JOKER_MODEL_NAME)
                logger.info("✅ Model załadowany przez MLX")
            
            # Opcja B: Transformers (Ubuntu z GPU)
            else:
                from transformers import AutoTokenizer, AutoModelForCausalLM
                import torch
                
                device = "cuda" if config.JOKER_USE_GPU and torch.cuda.is_available() else "cpu"
                self.tokenizer = AutoTokenizer.from_pretrained(config.JOKER_MODEL_NAME)
                self.model = AutoModelForCausalLM.from_pretrained(
                    config.JOKER_MODEL_NAME,
                    torch_dtype=torch.float16 if config.JOKER_QUANTIZATION == "fp16" else torch.float32,
                    device_map="auto" if device == "cuda" else None
                )
                if device == "cpu":
                    self.model = self.model.to(device)
                logger.info(f"✅ Model załadowany przez Transformers na {device}")
            
        except Exception as e:
            logger.error(f"❌ Błąd ładowania modelu: {e}")
            raise
    
    async def generate(self, request: JokeRequest) -> JokeResponse:
        """
        Wygeneruj żart na podstawie requestu
        """
        start_time = time.time()
        
        try:
            # Przygotuj prompt
            prompt = self._build_prompt(request)
            
            # Generuj żart
            joke = await self._generate_text(prompt, request)
            
            generation_time = time.time() - start_time
            
            return JokeResponse(
                success=True,
                joke=joke,
                topic=request.topic,
                style=request.style,
                generation_time=generation_time,
                model=config.JOKER_MODEL_NAME
            )
        
        except Exception as e:
            logger.error(f"Błąd generowania żartu: {e}")
            return JokeResponse(
                success=False,
                error=str(e)
            )
    
    def _build_prompt(self, request: JokeRequest) -> str:
        """Zbuduj prompt dla modelu"""
        prompt_parts = []
        
        if request.topic:
            prompt_parts.append(f"Temat: {request.topic}")
        
        prompt_parts.append(f"Styl: {request.style}")
        prompt_parts.append(f"Długość: {request.length}")
        prompt_parts.append("\nWygeneruj żart:")
        
        return "\n".join(prompt_parts)
    
    async def _generate_text(self, prompt: str, request: JokeRequest) -> str:
        """Wygeneruj tekst używając modelu"""
        # Implementacja zależna od wybranej biblioteki
        # Przykład dla MLX:
        if hasattr(self, 'model') and hasattr(self.model, 'generate'):
            from mlx_lm import generate
            response = generate(
                self.model,
                self.tokenizer,
                prompt=prompt,
                max_tokens=request.max_tokens,
                temp=request.temperature
            )
            return response
        
        # Przykład dla Transformers:
        else:
            inputs = self.tokenizer(prompt, return_tensors="pt")
            outputs = self.model.generate(
                **inputs,
                max_new_tokens=request.max_tokens,
                temperature=request.temperature,
                do_sample=True
            )
            return self.tokenizer.decode(outputs[0], skip_special_tokens=True)
```

### 5.3. Router

Utwórz `src/modules/joker/router.py`:

```python
"""
Router FastAPI dla serwisu Joker
"""

from fastapi import APIRouter, HTTPException, Depends
import logging
from .service import JokerService
from .models import JokeRequest, JokeResponse
from api.config import config
from api.dependencies import get_logger

logger = get_logger(__name__)
router = APIRouter()

# Inicjalizacja serwisu
try:
    service = JokerService()
    logger.info("✅ Serwis Joker zainicjalizowany")
except Exception as e:
    logger.error(f"❌ Błąd inicjalizacji serwisu Joker: {e}")
    service = None


@router.post("/generate", response_model=JokeResponse)
async def generate_joke(
    request: JokeRequest,
    logger: logging.Logger = Depends(get_logger)
):
    """
    Wygeneruj żart używając Bielik 7B
    
    - **topic**: Temat żartu (opcjonalne)
    - **style**: Styl żartu (sarcastic, witty, absurd) - domyślnie sarcastic
    - **length**: Długość (short, medium, long) - domyślnie medium
    - **temperature**: Temperatura generowania (0.0-2.0) - domyślnie 0.8
    - **max_tokens**: Maksymalna liczba tokenów (50-500) - domyślnie 200
    """
    if service is None:
        raise HTTPException(
            status_code=503,
            detail="Serwis Joker nie jest dostępny"
        )
    
    logger.info(f"Generowanie żartu: topic={request.topic}, style={request.style}")
    return await service.generate(request)


@router.get("/health")
async def health():
    """Health check dla serwisu Joker"""
    return {
        "status": "healthy" if service is not None else "unavailable",
        "model": config.JOKER_MODEL_NAME if service else None
    }
```

---

## 6. ROZWÓJ SERWISU AI-JOKE-ANALYSER

### 6.1. Modele Pydantic

Utwórz `src/modules/joke_analyser/models.py`:

```python
"""
Modele Pydantic dla serwisu Joke Analyser
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict


class JokeAnalysisRequest(BaseModel):
    """Request model dla analizy żartu"""
    joke: str = Field(..., description="Tekst żartu do analizy")
    techniques: Optional[List[str]] = Field(
        None,
        description="Lista technik analizy (opcjonalne, domyślnie wszystkie)"
    )


class TechniqueScore(BaseModel):
    """Wynik dla jednej techniki analizy"""
    technique: str
    score: float
    explanation: str


class JokeAnalysisResponse(BaseModel):
    """Response model dla analizy żartu"""
    success: bool
    joke: str
    overall_score: Optional[float] = None
    techniques: Optional[List[TechniqueScore]] = None
    sentiment: Optional[str] = None
    keywords: Optional[List[str]] = None
    analysis_time: Optional[float] = None
    error: Optional[str] = None
```

### 6.2. Serwis (service.py)

Utwórz `src/modules/joke_analyser/service.py`:

```python
"""
Serwis analizy żartów używający HerBERT + spaCy
"""

import time
import logging
from typing import List, Dict, Optional
import spacy
from transformers import AutoTokenizer, AutoModel
import torch

from .models import JokeAnalysisRequest, JokeAnalysisResponse, TechniqueScore
from api.config import config

logger = logging.getLogger(__name__)


class JokeAnalyserService:
    """Serwis analizy żartów"""
    
    # Lista dostępnych technik (z pliku techniki-rozkładu-żartu-na-czynniki-pierwsze.txt)
    AVAILABLE_TECHNIQUES = [
        "incongruity",
        "archetypes",
        "psychoanalysis",
        "setup_punchline",
        "semantic_shift",
        "absurd_escalation",
        "timing",
        "humor_micro_components",
        "reverse_engineering"
    ]
    
    def __init__(self):
        self.herbert_tokenizer = None
        self.herbert_model = None
        self.spacy_nlp = None
        self._load_models()
    
    def _load_models(self):
        """Załaduj modele HerBERT i spaCy"""
        try:
            logger.info("Ładowanie modeli analizy żartów...")
            
            # HerBERT
            logger.info("Ładowanie HerBERT...")
            self.herbert_tokenizer = AutoTokenizer.from_pretrained(config.JOKE_ANALYSER_MODEL_NAME)
            self.herbert_model = AutoModel.from_pretrained(config.JOKE_ANALYSER_MODEL_NAME)
            
            device = "cuda" if config.JOKE_ANALYSER_USE_GPU and torch.cuda.is_available() else "cpu"
            self.herbert_model = self.herbert_model.to(device)
            self.herbert_model.eval()
            logger.info(f"✅ HerBERT załadowany na {device}")
            
            # spaCy
            logger.info("Ładowanie spaCy...")
            self.spacy_nlp = spacy.load("pl_core_news_sm")
            logger.info("✅ spaCy załadowany")
            
        except Exception as e:
            logger.error(f"❌ Błąd ładowania modeli: {e}")
            raise
    
    async def analyze(self, request: JokeAnalysisRequest) -> JokeAnalysisResponse:
        """
        Przeanalizuj żart używając różnych technik
        """
        start_time = time.time()
        
        try:
            # Wybierz techniki do analizy
            techniques_to_analyze = request.techniques or self.AVAILABLE_TECHNIQUES
            
            # Wykonaj analizę dla każdej techniki
            technique_scores = []
            for technique in techniques_to_analyze:
                score = await self._analyze_technique(request.joke, technique)
                technique_scores.append(score)
            
            # Oblicz ogólny wynik
            overall_score = sum(t.score for t in technique_scores) / len(technique_scores) if technique_scores else 0.0
            
            # Analiza sentymentu i słów kluczowych
            sentiment = await self._analyze_sentiment(request.joke)
            keywords = await self._extract_keywords(request.joke)
            
            analysis_time = time.time() - start_time
            
            return JokeAnalysisResponse(
                success=True,
                joke=request.joke,
                overall_score=overall_score,
                techniques=technique_scores,
                sentiment=sentiment,
                keywords=keywords,
                analysis_time=analysis_time
            )
        
        except Exception as e:
            logger.error(f"Błąd analizy żartu: {e}")
            return JokeAnalysisResponse(
                success=False,
                joke=request.joke,
                error=str(e)
            )
    
    async def _analyze_technique(self, joke: str, technique: str) -> TechniqueScore:
        """Przeanalizuj żart pod kątem konkretnej techniki"""
        # Implementacja zależna od techniki
        # Przykład uproszczony:
        
        # Użyj HerBERT do ekstrakcji cech
        inputs = self.herbert_tokenizer(joke, return_tensors="pt", truncation=True, max_length=512)
        with torch.no_grad():
            outputs = self.herbert_model(**inputs)
            embeddings = outputs.last_hidden_state.mean(dim=1)
        
        # Uproszczony scoring (w rzeczywistości potrzebny trenowany klasyfikator)
        score = float(embeddings.mean().item()) % 1.0  # Przykład
        
        explanation = f"Analiza techniki {technique} dla żartu: {joke[:50]}..."
        
        return TechniqueScore(
            technique=technique,
            score=score,
            explanation=explanation
        )
    
    async def _analyze_sentiment(self, joke: str) -> str:
        """Analiza sentymentu żartu"""
        # Uproszczona analiza (w rzeczywistości potrzebny model sentymentu)
        doc = self.spacy_nlp(joke)
        # Implementacja analizy sentymentu
        return "positive"  # Placeholder
    
    async def _extract_keywords(self, joke: str) -> List[str]:
        """Wyciągnij słowa kluczowe z żartu"""
        doc = self.spacy_nlp(joke)
        keywords = [token.lemma_ for token in doc if token.pos_ in ["NOUN", "ADJ", "VERB"]]
        return keywords[:10]  # Top 10
```

### 6.3. Router

Utwórz `src/modules/joke_analyser/router.py`:

```python
"""
Router FastAPI dla serwisu Joke Analyser
"""

from fastapi import APIRouter, HTTPException, Depends
import logging
from .service import JokeAnalyserService
from .models import JokeAnalysisRequest, JokeAnalysisResponse
from api.config import config
from api.dependencies import get_logger

logger = get_logger(__name__)
router = APIRouter()

# Inicjalizacja serwisu
try:
    service = JokeAnalyserService()
    logger.info("✅ Serwis Joke Analyser zainicjalizowany")
except Exception as e:
    logger.error(f"❌ Błąd inicjalizacji serwisu Joke Analyser: {e}")
    service = None


@router.post("/analyze", response_model=JokeAnalysisResponse)
async def analyze_joke(
    request: JokeAnalysisRequest,
    logger: logging.Logger = Depends(get_logger)
):
    """
    Przeanalizuj żart używając różnych technik analizy
    
    - **joke**: Tekst żartu do analizy (wymagane)
    - **techniques**: Lista technik analizy (opcjonalne, domyślnie wszystkie)
    
    Dostępne techniki:
    - incongruity
    - archetypes
    - psychoanalysis
    - setup_punchline
    - semantic_shift
    - absurd_escalation
    - timing
    - humor_micro_components
    - reverse_engineering
    """
    if service is None:
        raise HTTPException(
            status_code=503,
            detail="Serwis Joke Analyser nie jest dostępny"
        )
    
    logger.info(f"Analiza żartu: {request.joke[:50]}...")
    return await service.analyze(request)


@router.get("/health")
async def health():
    """Health check dla serwisu Joke Analyser"""
    return {
        "status": "healthy" if service is not None else "unavailable",
        "model": config.JOKE_ANALYSER_MODEL_NAME if service else None,
        "available_techniques": service.AVAILABLE_TECHNIQUES if service else []
    }
```

---

## 7. KONFIGURACJA ŚRODOWISKOWA

### 7.1. Plik .env

Utwórz `.env` w katalogu głównym projektu:

```bash
# Podstawowe ustawienia
SERVICE_NAME=ai-local-core
HOST=127.0.0.1
PORT=5001
DEBUG=false

# Włączanie/wyłączanie modułów
ENABLE_IMAGE_DESCRIPTION=true
ENABLE_OLLAMA=true
ENABLE_JOKER=false
ENABLE_JOKE_ANALYSER=false

# Image Description
IMAGE_MODEL_NAME=Salesforce/blip-image-captioning-base

# Ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_DEFAULT_MODEL=llama2

# Joker (Bielik 7B)
JOKER_MODEL_NAME=piotradamczyk/bielik-7b-v0.1
JOKER_USE_GPU=true
JOKER_QUANTIZATION=int8

# Joke Analyser
JOKE_ANALYSER_MODEL_NAME=allegro/herbert-base-cased
JOKE_ANALYSER_USE_GPU=false
```

### 7.2. Konfiguracja dla różnych środowisk

**PC Ubuntu (joker):**
```bash
ENABLE_JOKER=true
ENABLE_JOKE_ANALYSER=false
PORT=5001
JOKER_USE_GPU=true
```

**M1 MacBook (analyser):**
```bash
ENABLE_JOKER=false
ENABLE_JOKE_ANALYSER=true
PORT=5002
JOKER_USE_GPU=false  # Dla analyser nie potrzebne
```

**Serwerownia (wszystko):**
```bash
ENABLE_JOKER=true
ENABLE_JOKE_ANALYSER=true
PORT=5001
JOKER_USE_GPU=true
```

---

## 8. TESTOWANIE

### 8.1. Uruchomienie serwera

```bash
# Z katalogu głównego projektu
cd /Users/piotradamczyk/Projects/Octadecimal/ai-local-core
source venv/bin/activate

# Uruchom serwer
python -m src.api.main

# Lub przez uvicorn bezpośrednio
uvicorn src.api.main:app --host 127.0.0.1 --port 5001 --reload
```

### 8.2. Testowanie endpointów

**Health check:**
```bash
curl http://127.0.0.1:5001/health
```

**Image Description:**
```bash
curl -X POST http://127.0.0.1:5001/describe/ \
  -H "Content-Type: application/json" \
  -d '{"image_url": "https://example.com/image.jpg", "max_length": 50}'
```

**Ollama Chat:**
```bash
curl -X POST http://127.0.0.1:5001/ollama/chat \
  -H "Content-Type: application/json" \
  -d '{"user": "Cześć, jak się masz?"}'
```

**Joker (jeśli włączony):**
```bash
curl -X POST http://127.0.0.1:5001/joker/generate \
  -H "Content-Type: application/json" \
  -d '{"topic": "programista", "style": "sarcastic", "length": "medium"}'
```

**Joke Analyser (jeśli włączony):**
```bash
curl -X POST http://127.0.0.1:5001/joke-analyser/analyze \
  -H "Content-Type: application/json" \
  -d '{"joke": "Dlaczego programista nie lubi natury? Bo ma za dużo bugów."}'
```

### 8.3. Dokumentacja API

FastAPI automatycznie generuje dokumentację:

- **Swagger UI:** http://127.0.0.1:5001/docs
- **ReDoc:** http://127.0.0.1:5001/redoc

### 8.4. Testy jednostkowe

Utwórz testy w `tests/unit/`:

```python
# tests/unit/test_joker.py
import pytest
from modules.joker.service import JokerService
from modules.joker.models import JokeRequest

@pytest.mark.asyncio
async def test_joker_generate():
    service = JokerService()
    request = JokeRequest(topic="programista", style="sarcastic")
    response = await service.generate(request)
    assert response.success is True
    assert response.joke is not None
```

Uruchom testy:
```bash
pytest tests/unit/
```

---

## 9. DEPLOYMENT

### 9.1. Uruchomienie jako serwis systemowy

**Ubuntu (systemd):**

Utwórz `/etc/systemd/system/ai-local-core.service`:

```ini
[Unit]
Description=AI Local Core FastAPI Service
After=network.target

[Service]
Type=simple
User=piotr
WorkingDirectory=/home/piotr/Projects/Octadecimal/ai-local-core
Environment="PATH=/home/piotr/Projects/Octadecimal/ai-local-core/venv/bin"
ExecStart=/home/piotr/Projects/Octadecimal/ai-local-core/venv/bin/uvicorn src.api.main:app --host 0.0.0.0 --port 5001
Restart=always

[Install]
WantedBy=multi-user.target
```

**Uruchomienie:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable ai-local-core
sudo systemctl start ai-local-core
sudo systemctl status ai-local-core
```

### 9.2. Uruchomienie na M1 MacBook

**LaunchAgent (macOS):**

Utwórz `~/Library/LaunchAgents/com.octadecimal.ai-local-core.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.octadecimal.ai-local-core</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/piotradamczyk/Projects/Octadecimal/ai-local-core/venv/bin/uvicorn</string>
        <string>src.api.main:app</string>
        <string>--host</string>
        <string>0.0.0.0</string>
        <string>--port</string>
        <string>5002</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/piotradamczyk/Projects/Octadecimal/ai-local-core</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

**Uruchomienie:**
```bash
launchctl load ~/Library/LaunchAgents/com.octadecimal.ai-local-core.plist
launchctl start com.octadecimal.ai-local-core
```

### 9.3. Integracja z waldus-api (Laravel)

W `waldus-api/.env`:

```php
AI_LOCAL_CORE_URL=http://192.168.1.100:5001  # PC Ubuntu
AI_JOKE_ANALYSER_URL=http://192.168.1.101:5002  # M1 MacBook
```

W kontrolerze Laravel:

```php
// Przykład użycia
$response = Http::post(config('services.ai_local_core.url') . '/joker/generate', [
    'topic' => 'programista',
    'style' => 'sarcastic'
]);
```

---

## 10. ROZWÓJ DALSZYCH SERWISÓW

### 10.1. Wzorzec dodawania nowego serwisu

1. **Utwórz strukturę katalogów:**
```bash
mkdir -p src/modules/nazwa_serwisu
touch src/modules/nazwa_serwisu/{__init__.py,router.py,service.py,models.py}
```

2. **Zaimplementuj modele (models.py):**
```python
from pydantic import BaseModel

class RequestModel(BaseModel):
    field: str

class ResponseModel(BaseModel):
    success: bool
    result: str
```

3. **Zaimplementuj serwis (service.py):**
```python
class Service:
    async def process(self, request: RequestModel) -> ResponseModel:
        # Logika biznesowa
        pass
```

4. **Zaimplementuj router (router.py):**
```python
from fastapi import APIRouter
from .service import Service
from .models import RequestModel, ResponseModel

router = APIRouter()
service = Service()

@router.post("/endpoint", response_model=ResponseModel)
async def endpoint(request: RequestModel):
    return await service.process(request)
```

5. **Dodaj do config.py:**
```python
ENABLE_NAZWA_SERWISU: bool = False
```

6. **Dodaj do main.py:**
```python
if config.ENABLE_NAZWA_SERWISU:
    from modules.nazwa_serwisu.router import router as nazwa_router
    app.include_router(nazwa_router, prefix="/nazwa", tags=["Nazwa"])
```

7. **Włącz w .env:**
```bash
ENABLE_NAZWA_SERWISU=true
```

---

## 11. TROUBLESHOOTING

### 11.1. Błąd: "Module not found"

**Problem:** Python nie znajduje modułów

**Rozwiązanie:**
```bash
# Upewnij się, że jesteś w katalogu głównym projektu
cd /Users/piotradamczyk/Projects/Octadecimal/ai-local-core

# Sprawdź PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)/src"

# Lub uruchom przez moduł
python -m src.api.main
```

### 11.2. Błąd: "Model not found"

**Problem:** Model Bielik/HerBERT nie został pobrany

**Rozwiązanie:**
```bash
# Dla Bielik (MLX)
python -c "from mlx_lm import load; load('piotradamczyk/bielik-7b-v0.1')"

# Dla HerBERT
python -c "from transformers import AutoTokenizer; AutoTokenizer.from_pretrained('allegro/herbert-base-cased')"
```

### 11.3. Błąd: "GPU not available"

**Problem:** GPU nie jest dostępne, ale `USE_GPU=true`

**Rozwiązanie:**
```bash
# Sprawdź dostępność GPU
python -c "import torch; print(torch.cuda.is_available())"

# Dla Mac (MPS)
python -c "import torch; print(torch.backends.mps.is_available())"

# Jeśli GPU niedostępne, ustaw w .env:
JOKER_USE_GPU=false
```

### 11.4. Błąd: "Port already in use"

**Problem:** Port 5001 jest już zajęty

**Rozwiązanie:**
```bash
# Znajdź proces używający portu
lsof -i :5001

# Zabij proces
kill -9 <PID>

# Lub zmień port w .env
PORT=5002
```

---

## 12. CHECKLIST MIGRACJI

- [ ] Backup istniejącego kodu Flask
- [ ] Aktualizacja `requirements.txt` (FastAPI, uvicorn, pydantic)
- [ ] Instalacja zależności (`pip install -r requirements.txt`)
- [ ] Utworzenie struktury katalogów modularnej
- [ ] Utworzenie `config.py` z konfiguracją
- [ ] Utworzenie `main.py` z FastAPI app
- [ ] Migracja endpointów Image Description
- [ ] Migracja endpointów Ollama
- [ ] Testowanie istniejących endpointów
- [ ] Implementacja serwisu ai-joker
- [ ] Implementacja serwisu ai-joke-analyser
- [ ] Konfiguracja `.env` dla różnych środowisk
- [ ] Testy jednostkowe
- [ ] Dokumentacja API (automatyczna przez FastAPI)
- [ ] Deployment na PC Ubuntu
- [ ] Deployment na M1 MacBook
- [ ] Integracja z waldus-api (Laravel)
- [ ] Monitoring i logi

---

## 13. DODATKOWE ZASOBY

### Dokumentacja:
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Uvicorn Documentation](https://www.uvicorn.org/)
- [MLX Documentation](https://ml-explore.github.io/mlx/)
- [Transformers Documentation](https://huggingface.co/docs/transformers/)

### Modele:
- [Bielik 7B v0.1](https://huggingface.co/piotradamczyk/bielik-7b-v0.1)
- [HerBERT](https://huggingface.co/allegro/herbert-base-cased)
- [spaCy Polish](https://spacy.io/models/pl)

### Architektura:
- Zobacz: `waldus-api/docs/analysis/architektura-rozproszona-realna-sytuacja.md`

---

**Koniec instrukcji migracji i rozwoju serwisów AI**

