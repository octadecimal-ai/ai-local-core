# Testy jednostkowe - Instrukcja

## 📋 Spis treści

1. [Instalacja](#instalacja)
2. [Uruchamianie testów](#uruchamianie-testów)
3. [Struktura testów](#struktura-testów)
4. [Coverage](#coverage)
5. [Pisanie nowych testów](#pisanie-nowych-testów)

## 🔧 Instalacja

### Wymagania

- Python 3.8+
- Virtual environment (zalecane)

### Instalacja pytest

```bash
# Aktywuj virtual environment
source venv/bin/activate

# Zainstaluj pytest i pytest-cov
pip install pytest pytest-cov
```

Lub użyj requirements.txt (jeśli dodamy pytest do requirements):

```bash
pip install -r requirements.txt
```

## 🚀 Uruchamianie testów

### Podstawowe komendy

```bash
# Aktywuj środowisko
source venv/bin/activate

# Wszystkie testy jednostkowe
pytest tests/unit/ -v

# Wszystkie testy (unit + integration)
pytest tests/ -v

# Konkretny plik testowy
pytest tests/unit/test_ollama_client.py -v

# Konkretny test
pytest tests/unit/test_ollama_client.py::TestOllamaClient::test_chat_success -v
```

### Z raportem pokrycia (coverage)

```bash
# Coverage w terminalu
pytest tests/ --cov=src --cov-report=term-missing

# Coverage z raportem HTML
pytest tests/ --cov=src --cov-report=html --cov-report=term-missing
# Następnie otwórz htmlcov/index.html w przeglądarce

# Tylko testy jednostkowe z coverage
pytest tests/unit/ --cov=src --cov-report=term-missing
```

### Użycie skryptu pomocniczego

```bash
# Uruchom wszystkie testy z coverage
./scripts/run-tests.sh

# Z dodatkowymi opcjami
./scripts/run-tests.sh -v --tb=short
```

## 📁 Struktura testów

```
tests/
├── __init__.py
├── unit/                          # Testy jednostkowe
│   ├── __init__.py
│   ├── test_ollama_client.py     # 15 testów dla OllamaClient
│   └── test_translation.py       # 3 testy dla Translation
└── integration/                   # Testy integracyjne
    └── __init__.py
```

## 📊 Coverage

### Aktualne pokrycie

| Moduł | Coverage | Status |
|-------|----------|--------|
| `src/ollama/client.py` | 96% | ✅ |
| `src/ollama/exceptions.py` | 100% | ✅ |
| `src/ollama/__init__.py` | 100% | ✅ |
| `src/translation/__init__.py` | 100% | ✅ |
| `src/translation/translate.py` | 32% | ⚠️ |
| `src/ollama/complete.py` | 16% | ⚠️ (stary kod) |

**Całkowite pokrycie: 32%**

### Wyświetlanie coverage

```bash
# W terminalu
pytest tests/ --cov=src --cov-report=term-missing

# W HTML (otwórz htmlcov/index.html)
pytest tests/ --cov=src --cov-report=html
```

## ✍️ Pisanie nowych testów

### Przykład testu dla OllamaClient

```python
import pytest
from unittest.mock import Mock, patch
from ollama.client import OllamaClient

class TestOllamaClient:
    @patch('ollama.client.requests.post')
    def test_chat_success(self, mock_post):
        """Test udanego chat completion"""
        # Mock response
        mock_response = Mock()
        mock_response.json.return_value = {
            'message': {'content': 'Hello!'},
            'prompt_eval_count': 10,
            'eval_count': 5
        }
        mock_response.raise_for_status = Mock()
        mock_post.return_value = mock_response
        
        # Test
        client = OllamaClient()
        result = client.chat(user="Hello")
        
        # Assertions
        assert result['text'] == 'Hello!'
        assert result['usage']['input_tokens'] == 10
```

### Konwencje nazewnictwa

- Pliki testowe: `test_*.py`
- Klasy testowe: `Test*`
- Funkcje testowe: `test_*`

### Uruchamianie nowego testu

```bash
# Tylko nowy test
pytest tests/unit/test_new_module.py -v

# Z verbose output
pytest tests/unit/test_new_module.py -v -s
```

## 🔍 Opcje pytest

### Podstawowe opcje

```bash
# Verbose (szczegółowy output)
pytest tests/ -v

# Bardzo szczegółowy (pokazuje printy)
pytest tests/ -v -s

# Krótki traceback przy błędach
pytest tests/ --tb=short

# Tylko pierwszy błąd (stop on first failure)
pytest tests/ -x

# Ignoruj cache
pytest tests/ --cache-clear
```

### Filtrowanie testów

```bash
# Tylko testy zawierające "chat" w nazwie
pytest tests/ -k "chat" -v

# Tylko testy z markerem "unit"
pytest tests/ -m unit -v

# Pomiń testy z markerem "slow"
pytest tests/ -m "not slow" -v
```

## 🐛 Troubleshooting

### Problem: ModuleNotFoundError

```bash
# Upewnij się, że jesteś w katalogu projektu
cd /Users/piotradamczyk/Projects/Octadecimal/ai-local-core

# Aktywuj virtual environment
source venv/bin/activate

# Sprawdź czy pytest jest zainstalowany
pip list | grep pytest
```

### Problem: Import errors

Testy automatycznie dodają `src/` do PYTHONPATH. Jeśli masz problemy:

```python
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'src'))
```

### Problem: Testy nie znajdują modułów

```bash
# Sprawdź strukturę katalogów
ls -la src/
ls -la tests/unit/

# Uruchom z verbose
pytest tests/ -v -s
```

## 📝 Przykłady

### Przykład 1: Test z mockowaniem

```python
from unittest.mock import Mock, patch
import pytest

@patch('module.external_api')
def test_with_mock(mock_api):
    mock_api.return_value = {'status': 'ok'}
    result = function_under_test()
    assert result == 'expected'
```

### Przykład 2: Test z parametrami

```python
@pytest.mark.parametrize("input,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
])
def test_uppercase(input, expected):
    assert input.upper() == expected
```

### Przykład 3: Test z fixtures

```python
@pytest.fixture
def client():
    return OllamaClient(base_url='http://test:11434')

def test_with_fixture(client):
    assert client.base_url == 'http://test:11434'
```

## 📚 Dodatkowe zasoby

- [Dokumentacja pytest](https://docs.pytest.org/)
- [pytest-cov documentation](https://pytest-cov.readthedocs.io/)
- [unittest.mock documentation](https://docs.python.org/3/library/unittest.mock.html)

---

**Ostatnia aktualizacja:** 2025-11-09  
**Status:** ✅ Testy działają (18 testów, wszystkie przechodzą)

