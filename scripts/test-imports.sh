#!/bin/bash
# Test importów wszystkich modułów

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"
source venv/bin/activate

echo "🧪 Testing imports..."

echo -n "  Ollama: "
python3 -c "import sys; sys.path.insert(0, 'src'); from ollama.complete import complete; print('✅ OK')" 2>&1 | grep -q "OK" && echo "✅ OK" || echo "❌ FAILED"

echo -n "  Image: "
python3 -c "import sys; sys.path.insert(0, 'src'); from image.describe import describe_image; print('✅ OK')" 2>&1 | grep -q "OK" && echo "✅ OK" || echo "❌ FAILED"

echo -n "  Translation: "
python3 -c "import sys; sys.path.insert(0, 'src'); from translation.translate import translate_text; print('✅ OK')" 2>&1 | grep -q "OK" && echo "✅ OK" || echo "❌ FAILED"

echo -n "  API Server: "
python3 -c "import sys; sys.path.insert(0, 'src'); from api.server import app; print('✅ OK')" 2>&1 | grep -q "OK" && echo "✅ OK" || echo "❌ FAILED"

echo "✅ All imports tested!"

