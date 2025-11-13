"""
Router FastAPI dla serwisu Joker
"""

from fastapi import APIRouter, HTTPException, Depends
import logging
import sys
import os

# Dodaj ścieżkę do src do PYTHONPATH
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

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

