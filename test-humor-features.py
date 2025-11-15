#!/usr/bin/env python3
"""
Test script dla HumorFeatureExtractor
"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

import asyncio
from humor_features import HumorFeatureExtractor, ExtractRequest


async def main():
    print("🧪 Test HumorFeatureExtractor\n")
    
    # Test joke
    joke = "Dlaczego programista poszedł do lasu? Bo szukał drzewa binarnego!"
    
    print(f"📝 Żart: {joke}\n")
    
    # Initialize extractor
    print("⏳ Inicjalizacja extractora...")
    try:
        extractor = HumorFeatureExtractor()
        print("✅ Extractor zainicjalizowany\n")
    except Exception as e:
        print(f"❌ Błąd inicjalizacji: {e}")
        return
    
    # Extract features
    print("🔍 Ekstrakcja features...")
    request = ExtractRequest(joke_text=joke)
    
    try:
        response = await extractor.extract(request)
        print(f"✅ Features wyekstraktowane w {response.extraction_time_ms:.2f}ms\n")
        
        features = response.features
        
        # Print features
        print("=" * 60)
        print("📊 WYNIKI EKSTRAKCJI\n")
        
        print(f"📏 Podstawowe:")
        print(f"  - Znaki: {features.char_count}")
        print(f"  - Słowa: {features.word_count}")
        print(f"  - Język: {features.language}\n")
        
        print(f"🏗️  Strukturalne:")
        print(f"  - Zdań: {features.structural.sentence_count}")
        print(f"  - Ma pytanie: {features.structural.has_question}")
        print(f"  - Clear punchline: {features.structural.has_clear_punchline}")
        print(f"  - Setup length: {features.structural.setup_length}")
        print(f"  - Punchline length: {features.structural.punchline_length}\n")
        
        print(f"🔑 Keywords:")
        print(f"  - Tech words: {features.keywords.tech_words}")
        print(f"  - Emotion words: {features.keywords.emotion_words}")
        print(f"  - Regional markers: {features.keywords.regional_markers}")
        print(f"  - Archetypes: {features.keywords.archetypes}")
        print(f"  - Surprise words: {features.keywords.surprise_words}\n")
        
        print(f"📝 Lingwistyczne:")
        print(f"  - POS tags: {dict(list(features.linguistic.pos_tags.items())[:5])}")
        print(f"  - Entities: {features.linguistic.entities}")
        print(f"  - Comparisons: {features.linguistic.comparisons_count}")
        print(f"  - Negations: {features.linguistic.negations_count}\n")
        
        print(f"⚛️  Atomy humorystyczne:")
        print(f"  - Emoji: {features.atomic.emoji_count}")
        print(f"  - Wykrzykniki: {features.atomic.exclamation_count}")
        print(f"  - CAPS words: {features.atomic.caps_words_count}")
        print(f"  - Repetitions: {features.atomic.repetitions}")
        print(f"  - Hyperboles: {features.atomic.hyperboles}\n")
        
        print(f"🧠 Semantyczne:")
        print(f"  - Polysemy words: {features.semantic.polysemy_words[:5]}")
        print(f"  - Wordplay candidates: {features.semantic.wordplay_candidates}")
        print(f"  - Semantic fields: {features.semantic.semantic_fields}\n")
        
        print(f"⏱️  Timing:")
        print(f"  - Word count: {features.timing.word_count}")
        print(f"  - Reading time: {features.timing.reading_time_sec}s")
        print(f"  - Rhythm score: {features.timing.rhythm_score}")
        print(f"  - Pause indicators: {features.timing.pause_indicators}\n")
        
        print(f"📖 Narracyjne:")
        print(f"  - Perspective: {features.narrative.narrative_perspective}")
        print(f"  - Emotional arc: {features.narrative.emotional_arc}")
        print(f"  - Conflict: {features.narrative.conflict_present}")
        print(f"  - Resolution: {features.narrative.resolution_present}\n")
        
        print(f"🎭 Absurd:")
        print(f"  - Contradictions: {features.absurdity.contradiction_count}")
        print(f"  - Impossibility markers: {features.absurdity.impossibility_markers}")
        print(f"  - Exaggeration words: {features.absurdity.exaggeration_words}")
        print(f"  - Logical breaks: {features.absurdity.logical_breaks}\n")
        
        print("=" * 60)
        print("✅ Test zakończony pomyślnie!")
        
    except Exception as e:
        print(f"❌ Błąd ekstrakcji: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())

