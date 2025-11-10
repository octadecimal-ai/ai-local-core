#!/bin/bash
# Skrypt do aktywacji virtual environment

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -d "$PROJECT_DIR/venv" ]; then
    source "$PROJECT_DIR/venv/bin/activate"
    echo "✅ Virtual environment activated"
    echo "Python: $(python --version)"
    echo "Pip: $(pip --version | cut -d' ' -f1-2)"
else
    echo "❌ Virtual environment not found. Run: python3 -m venv venv"
    exit 1
fi

