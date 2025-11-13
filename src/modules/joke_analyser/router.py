"""
Router FastAPI dla serwisu Joke Analyser
"""

from fastapi import APIRouter, HTTPException, Depends
import logging
import sys
import os

# Dodaj ścieżkę do src do PYTHONPATH
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

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

