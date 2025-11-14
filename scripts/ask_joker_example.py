#!/usr/bin/env python3
"""
Przykładowe użycie skryptu ask_joker.py
"""

import sys
import os

# Dodaj ścieżkę do scripts
sys.path.insert(0, os.path.dirname(__file__))

from ask_joker import generate_joke, check_health

# URL serwera
URL = "http://127.0.0.1:5001"

def example_basic():
    """Przykład podstawowego użycia"""
    print("=" * 60)
    print("Przykład 1: Podstawowe użycie z tematem")
    print("=" * 60)
    
    result = generate_joke(
        url=URL,
        topic="programista",
        style="sarcastic"
    )
    
    if result.get("success"):
        print(f"✅ Sukces!")
        print(f"Żart: {result.get('joke')}")
        print(f"Czas: {result.get('generation_time', 0):.2f}s")
    else:
        print(f"❌ Błąd: {result.get('error')}")
    
    print()


def example_different_styles():
    """Przykład z różnymi stylami"""
    print("=" * 60)
    print("Przykład 2: Różne style")
    print("=" * 60)
    
    styles = ["sarcastic", "witty", "absurd"]
    
    for style in styles:
        print(f"\nStyl: {style}")
        result = generate_joke(
            url=URL,
            topic="Python",
            style=style,
            length="short"
        )
        
        if result.get("success"):
            print(f"  {result.get('joke', 'Brak żartu')}")
        else:
            print(f"  Błąd: {result.get('error')}")
    
    print()


def example_custom_params():
    """Przykład z niestandardowymi parametrami"""
    print("=" * 60)
    print("Przykład 3: Niestandardowe parametry")
    print("=" * 60)
    
    result = generate_joke(
        url=URL,
        topic="sztuczna inteligencja",
        style="witty",
        length="long",
        temperature=0.9,
        max_tokens=300
    )
    
    if result.get("success"):
        print(f"✅ Sukces!")
        print(f"Żart: {result.get('joke')}")
        print(f"Parametry:")
        print(f"  - Temperature: {result.get('style')}")
        print(f"  - Max tokens: {result.get('max_tokens', 'N/A')}")
        print(f"  - Czas: {result.get('generation_time', 0):.2f}s")
    else:
        print(f"❌ Błąd: {result.get('error')}")
    
    print()


def example_no_topic():
    """Przykład bez tematu"""
    print("=" * 60)
    print("Przykład 4: Bez tematu (ogólny żart)")
    print("=" * 60)
    
    result = generate_joke(
        url=URL,
        style="absurd",
        length="medium"
    )
    
    if result.get("success"):
        print(f"✅ Sukces!")
        print(f"Żart: {result.get('joke')}")
    else:
        print(f"❌ Błąd: {result.get('error')}")
    
    print()


def main():
    """Uruchom wszystkie przykłady"""
    print("🎭 Przykłady użycia skryptu ask_joker.py")
    print()
    
    # Sprawdź health check
    print("Sprawdzanie dostępności serwisu...")
    if not check_health(URL):
        print(f"❌ Serwis Joker nie jest dostępny pod adresem {URL}")
        print("   Upewnij się, że serwer jest uruchomiony i moduł Joker jest włączony.")
        sys.exit(1)
    
    print("✅ Serwis Joker jest dostępny")
    print()
    
    # Uruchom przykłady
    try:
        example_basic()
        example_different_styles()
        example_custom_params()
        example_no_topic()
        
        print("=" * 60)
        print("✅ Wszystkie przykłady zakończone")
        print("=" * 60)
    
    except KeyboardInterrupt:
        print("\n\nPrzerwano przez użytkownika")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Błąd: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

