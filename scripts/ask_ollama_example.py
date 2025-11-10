#!/usr/bin/env python3
"""
Przykład użycia ask_ollama.py z różnymi konfiguracjami
"""

# Przykład 1: Proste pytanie
PYTANIE_1 = "Co to jest sztuczna inteligencja?"
SYSTEM_PROMPT_1 = None
MODEL_1 = None
TEMPERATURE_1 = 0.7
MAX_TOKENS_1 = 150

# Przykład 2: Kreatywne zadanie
PYTANIE_2 = "Napisz krótki wiersz o programowaniu"
SYSTEM_PROMPT_2 = "Jesteś kreatywnym poetą. Pisz krótkie, inspirujące wiersze."
MODEL_2 = "llama3.1:8b"
TEMPERATURE_2 = 0.9  # Wyższa temperatura = bardziej kreatywne
MAX_TOKENS_2 = 100

# Przykład 3: Techniczne pytanie
PYTANIE_3 = "Wyjaśnij różnicę między listą a krotką w Pythonie"
SYSTEM_PROMPT_3 = "Jesteś ekspertem od Pythona. Odpowiadaj precyzyjnie i technicznie."
MODEL_3 = "llama3.1:8b"
TEMPERATURE_3 = 0.3  # Niższa temperatura = bardziej precyzyjne
MAX_TOKENS_3 = 200

# Aby użyć któregoś z przykładów, skopiuj wartości do ask_ollama.py:
# PYTANIE = PYTANIE_1
# SYSTEM_PROMPT = SYSTEM_PROMPT_1
# MODEL = MODEL_1
# TEMPERATURE = TEMPERATURE_1
# MAX_TOKENS = MAX_TOKENS_1

