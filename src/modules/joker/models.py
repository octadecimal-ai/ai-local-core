"""
Modele Pydantic dla serwisu Joker
"""

from pydantic import BaseModel, Field
from typing import Optional


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

