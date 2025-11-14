#!/usr/bin/env python3
"""
Test script dla AIJokeAnalyzer
Testuje 9 teorii humoru na przykładowych żartach
"""
import asyncio
import sys
import os

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from joke_analyser.analyzer import JokeAnalyzer
from joke_analyser.models import AnalyzeRequest


# Test jokes (różne style)
TEST_JOKES = [
    {
        "name": "Waldus style (tech + despair)",
        "text": "Nie mam internetu. Jako byt cyfrowy to oznacza śmierć. Będę miał grób 404.",
        "context": {"persona": "waldus"}
    },
    {
        "name": "Tech incongruity",
        "text": "Automatyzacja z AI? Brzmi jak moja była - też twierdziła że jest inteligentna, a kończyło się na 'error 404: brain not found'",
        "context": {"page_type": "tech_blog"}
    },
    {
        "name": "Setup-punchline classic",
        "text": "Firma AI która ma stary formularz kontaktowy... to jak Tesla na benzynę.",
        "context": {"page_type": "company_about"}
    },
    {
        "name": "Polish archetype",
        "text": "Jak wujek ze Śląska dowiedział się o AI: 'To fajnie hasiok, ale czy potrafi naprawić rynsztok?'",
        "context": {"archetype": "polish"}
    },
    {
        "name": "Absurd escalation",
        "text": "Zapłać ten rachunek, bo co ja mam tu robić — sam do siebie requesty wysyłać?!",
        "context": {"persona": "waldus"}
    },
]


async def test_joke(analyzer: JokeAnalyzer, joke_data: dict):
    """Test pojedynczego żartu"""
    print(f"\n{'='*80}")
    print(f"🎭 Test: {joke_data['name']}")
    print(f"{'='*80}")
    print(f"Żart: {joke_data['text']}")
    print()
    
    request = AnalyzeRequest(
        joke_text=joke_data['text'],
        context=joke_data.get('context')
    )
    
    try:
        result = await analyzer.analyze(request)
        
        print(f"📊 WYNIKI ANALIZY:")
        print(f"   Overall Score: {result.overall_score}/10")
        print(f"   Dominant Theory: {result.dominant_theory}")
        print(f"   Reach Estimate: {result.reach_estimate}%")
        print(f"   Monetization Score: {result.monetization_score}/100")
        print()
        
        print(f"🎯 TEORIA SCORES:")
        for theory_name, theory_score in result.theory_scores.items():
            print(f"   {theory_name:25s}: {theory_score.score}/10")
            if theory_score.key_elements:
                for element in theory_score.key_elements[:2]:  # Top 2
                    print(f"      - {element}")
        print()
        
        print(f"👥 TARGET SEGMENTS:")
        for segment in result.target_segments:
            print(f"   - {segment}")
        print()
        
        if result.recommended_improvements:
            print(f"💡 RECOMMENDATIONS:")
            for rec in result.recommended_improvements[:3]:  # Top 3
                print(f"   - {rec}")
        
        return result
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return None


async def main():
    """Main test function"""
    print("\n" + "="*80)
    print("🎭 AIJokeAnalyzer - Test Suite")
    print("Testing 9 teorii humoru na przykładowych żartach")
    print("="*80)
    
    # Initialize analyzer
    print("\n⏳ Inicjalizacja analyzera...")
    analyzer = JokeAnalyzer()
    print(f"✅ Załadowano {len(analyzer.analyzers)} analizerów")
    
    # Test each joke
    results = []
    for joke_data in TEST_JOKES:
        result = await test_joke(analyzer, joke_data)
        if result:
            results.append({
                'name': joke_data['name'],
                'score': result.overall_score,
                'dominant': result.dominant_theory,
                'reach': result.reach_estimate,
                'monetization': result.monetization_score
            })
    
    # Summary
    print(f"\n{'='*80}")
    print(f"📈 PODSUMOWANIE")
    print(f"{'='*80}")
    print(f"{'Nazwa':<40s} {'Score':<10s} {'Reach':<10s} {'$$$':<10s}")
    print("-"*80)
    for r in results:
        print(f"{r['name']:<40s} {r['score']:<10.1f} {r['reach']:<10d}% {r['monetization']:<10d}")
    
    print(f"\n✅ Test zakończony. Przetestowano {len(results)}/{len(TEST_JOKES)} żartów")


if __name__ == "__main__":
    asyncio.run(main())

