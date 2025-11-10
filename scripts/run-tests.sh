#!/bin/bash
# Skrypt do uruchamiania testów

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"
source venv/bin/activate

echo "🧪 Running tests..."
echo ""

# Uruchom testy z coverage
pytest tests/ -v --cov=src --cov-report=term-missing "$@"

