"""
Serwis generowania żartów używający Bielik 7B
"""

import time
import logging
import sys
import os
from typing import Optional

# Dodaj ścieżkę do src do PYTHONPATH
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

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
            try:
                import mlx_lm
                if config.JOKER_USE_GPU:
                    from mlx_lm import load
                    self.model, self.tokenizer = load(config.JOKER_MODEL_NAME)
                    logger.info("✅ Model załadowany przez MLX")
                    return
            except ImportError:
                logger.debug("MLX nie dostępne, używam Transformers")
            
            # Opcja B: Transformers (Ubuntu z GPU lub CPU)
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
        # Sprawdź czy to MLX
        try:
            import mlx_lm
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
        except (ImportError, AttributeError):
            pass
        
        # Transformers
        inputs = self.tokenizer(prompt, return_tensors="pt")
        outputs = self.model.generate(
            **inputs,
            max_new_tokens=request.max_tokens,
            temperature=request.temperature,
            do_sample=True
        )
        return self.tokenizer.decode(outputs[0], skip_special_tokens=True)

