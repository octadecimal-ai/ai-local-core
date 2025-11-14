#!/bin/bash
# Start AIJokeAnalyzer na M1 MacBook (port 5002)
# Date: 2025-11-14

echo "🎭 Starting AIJokeAnalyzer on M1 MacBook"
echo "========================================"

# Get M1 local IP
M1_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
echo "M1 Local IP: $M1_IP"

# Activate venv
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Run setup-joke-analyser-m1.sh first"
    exit 1
fi

echo ""
echo "Activating virtual environment..."
source venv/bin/activate

# Set environment variables
export ENABLE_IMAGE_DESCRIPTION=false
export ENABLE_OLLAMA=false
export ENABLE_JOKER=false
export ENABLE_JOKE_ANALYSER=true
export PORT=5002
export HOST=0.0.0.0
export SERVICE_NAME="joke-analyser-m1"

echo ""
echo "Configuration:"
echo "  ENABLE_JOKE_ANALYSER=true"
echo "  PORT=5002"
echo "  HOST=0.0.0.0"
echo ""

# Start server
echo "🚀 Starting FastAPI server..."
echo "   Local:    http://localhost:5002/docs"
echo "   Network:  http://$M1_IP:5002/docs"
echo ""
echo "Press Ctrl+C to stop"
echo ""

cd src
python -m uvicorn api.main:app --host 0.0.0.0 --port 5002 --reload

