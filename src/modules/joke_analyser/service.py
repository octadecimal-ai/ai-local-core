"""
Serwis analizy żartów używający HerBERT + spaCy
"""

import time
import logging
import sys
import os
from typing import List, Optional

# Dodaj ścieżkę do src do PYTHONPATH
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

import spacy
from transformers import AutoTokenizer, AutoModel
import torch

from .models import JokeAnalysisRequest, JokeAnalysisResponse, TechniqueScore
from api.config import config

logger = logging.getLogger(__name__)


class JokeAnalyserService:
    """Serwis analizy żartów"""
    
    # Lista dostępnych technik
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
        # Użyj HerBERT do ekstrakcji cech
        inputs = self.herbert_tokenizer(joke, return_tensors="pt", truncation=True, max_length=512)
        with torch.no_grad():
            outputs = self.herbert_model(**inputs)
            embeddings = outputs.last_hidden_state.mean(dim=1)
        
        # Uproszczony scoring (w rzeczywistości potrzebny trenowany klasyfikator)
        score = float(embeddings.mean().item()) % 1.0
        
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

