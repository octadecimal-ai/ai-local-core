#!/bin/bash
# Setup AIJokeAnalyzer na M1 MacBook
# Date: 2025-11-14

echo "🎭 Setup AIJokeAnalyzer dla M1 MacBook"
echo "======================================="

# 1. Check Python version
echo ""
echo "1. Sprawdzanie wersji Python..."
python3 --version

if [ $? -ne 0 ]; then
    echo "❌ Python3 nie znaleziony. Zainstaluj Python 3.11+"
    exit 1
fi

# 2. Create virtual environment (if not exists)
if [ ! -d "venv" ]; then
    echo ""
    echo "2. Tworzenie virtual environment..."
    python3 -m venv venv
else
    echo ""
    echo "2. Virtual environment już istnieje"
fi

# 3. Activate virtual environment
echo ""
echo "3. Aktywowanie virtual environment..."
source venv/bin/activate

# 4. Install requirements
echo ""
echo "4. Instalacja zależności..."
pip install --upgrade pip
pip install -r requirements-joke-analyser.txt

# 5. Download spaCy Polish model
echo ""
echo "5. Pobieranie polskiego modelu spaCy..."
python -m spacy download pl_core_news_lg

if [ $? -ne 0 ]; then
    echo "⚠️  Nie udało się pobrać pl_core_news_lg, próba z pl_core_news_sm..."
    python -m spacy download pl_core_news_sm
fi

# 6. Test import
echo ""
echo "6. Test importów..."
python3 -c "
import spacy
from joke_analyser.analyzer import JokeAnalyzer
print('✅ Wszystkie importy OK')
"

if [ $? -ne 0 ]; then
    echo "❌ Błąd importów. Sprawdź instalację."
    exit 1
fi

echo ""
echo "✅ Setup zakończony pomyślnie!"
echo ""
echo "🚀 Uruchom serwer:"
echo "   source venv/bin/activate"
echo "   uvicorn src.api.main:app --host 0.0.0.0 --port 5002"
echo ""
echo "📖 Dokumentacja API:"
echo "   http://localhost:5002/docs"

