"""
Modele Pydantic dla serwisu Joke Analyser
"""

from pydantic import BaseModel, Field
from typing import Optional, List


class TechniqueScore(BaseModel):
    """Wynik dla jednej techniki analizy"""
    technique: str
    score: float
    explanation: str


class JokeAnalysisRequest(BaseModel):
    """Request model dla analizy żartu"""
    joke: str = Field(..., description="Tekst żartu do analizy")
    techniques: Optional[List[str]] = Field(
        None,
        description="Lista technik analizy (opcjonalne, domyślnie wszystkie)"
    )


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

