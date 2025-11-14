#!/usr/bin/env python3
"""
Test AIJokeAnalyzer na klasycznych żartach Waldusia

Usage:
    python test-waldus-classics.py
"""
import asyncio
import json
import sys
import os
from pathlib import Path
from datetime import datetime

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from joke_analyser.analyzer import JokeAnalyzer
from joke_analyser.models import AnalyzeRequest


async def main():
    print("🎭 AIJokeAnalyzer - Test na Klasycznych Żartach Waldusia")
    print("="*80)
    print()
    
    # Load jokes
    jokes_file = Path(__file__).parent / 'validation' / 'test-waldus-classics.json'
    
    if not jokes_file.exists():
        print(f"❌ Nie znaleziono pliku: {jokes_file}")
        return
    
    with open(jokes_file, 'r', encoding='utf-8') as f:
        dataset = json.load(f)
    
    print(f"📚 Dataset: {dataset['dataset_name']}")
    print(f"📅 Created: {dataset['date_created']}")
    print(f"🎯 Source: {dataset['source']}")
    print(f"🔢 Jokes count: {len(dataset['jokes'])}")
    print()
    
    # Initialize analyzer
    analyzer = JokeAnalyzer()
    
    # Results storage
    results = []
    
    # Analyze each joke
    for i, joke_data in enumerate(dataset['jokes'], 1):
        joke_text = joke_data['text']
        joke_id = joke_data['id']
        metadata = joke_data['metadata']
        
        print(f"\n{'='*80}")
        print(f"🎯 Żart #{joke_id} (Line {metadata['line']})")
        print(f"{'='*80}")
        print(f"\n📝 Text:\n{joke_text}\n")
        print(f"🎭 Context: {metadata['context']}")
        print(f"🔮 Expected theories: {', '.join(metadata['expected_theories'])}")
        print(f"\n⏳ Analyzing...")
        
        # Analyze
        result = await analyzer.analyze(AnalyzeRequest(joke_text=joke_text))
        
        # Display results
        print(f"\n📊 RESULTS:")
        print(f"   Overall Score: {result.overall_score:.2f}/10")
        print(f"\n   Theory Scores:")
        
        # Sort by score (descending)
        sorted_theories = sorted(
            result.theory_scores.items(),
            key=lambda x: x[1].score,
            reverse=True
        )
        
        for theory_name, theory_result in sorted_theories:
            emoji = "🔥" if theory_result.score >= 8 else "✅" if theory_result.score >= 6 else "➖"
            expected = "⭐" if theory_name in metadata['expected_theories'] else ""
            print(f"   {emoji} {theory_name:20s}: {theory_result.score:5.2f}/10 {expected}")
        
        # Check if expected theories are in top 3
        top3_theories = [t[0] for t in sorted_theories[:3]]
        expected_in_top3 = [t for t in metadata['expected_theories'] if t in top3_theories]
        
        print(f"\n   🎯 Top 3 theories: {', '.join(top3_theories)}")
        print(f"   ✅ Expected in top 3: {len(expected_in_top3)}/{len(metadata['expected_theories'])}")
        
        # Store result
        results.append({
            'joke_id': joke_id,
            'text': joke_text,
            'overall_score': result.overall_score,
            'theory_scores': {
                name: score.score 
                for name, score in result.theory_scores.items()
            },
            'top3_theories': top3_theories,
            'expected_theories': metadata['expected_theories'],
            'expected_match_count': len(expected_in_top3),
            'context': metadata['context']
        })
    
    # Summary
    print(f"\n\n{'='*80}")
    print("📊 PODSUMOWANIE")
    print(f"{'='*80}\n")
    
    # Overall statistics
    avg_score = sum(r['overall_score'] for r in results) / len(results)
    min_score = min(r['overall_score'] for r in results)
    max_score = max(r['overall_score'] for r in results)
    
    print(f"Overall Scores:")
    print(f"   Average: {avg_score:.2f}/10")
    print(f"   Min:     {min_score:.2f}/10 (Żart #{[r['joke_id'] for r in results if r['overall_score'] == min_score][0]})")
    print(f"   Max:     {max_score:.2f}/10 (Żart #{[r['joke_id'] for r in results if r['overall_score'] == max_score][0]})")
    
    # Expected theory match rate
    total_expected = sum(len(r['expected_theories']) for r in results)
    total_matched = sum(r['expected_match_count'] for r in results)
    match_rate = (total_matched / total_expected * 100) if total_expected > 0 else 0
    
    print(f"\nExpected Theory Detection:")
    print(f"   Match rate: {match_rate:.1f}% ({total_matched}/{total_expected})")
    
    # Theory frequency in top 3
    theory_freq = {}
    for result in results:
        for theory in result['top3_theories']:
            theory_freq[theory] = theory_freq.get(theory, 0) + 1
    
    print(f"\nMost Common Theories in Top 3:")
    for theory, count in sorted(theory_freq.items(), key=lambda x: x[1], reverse=True)[:5]:
        print(f"   {theory:20s}: {count:2d} times ({count/len(results)*100:.0f}%)")
    
    # Best and worst jokes
    print(f"\n🏆 Top 3 Najlepsze Żarty:")
    for i, result in enumerate(sorted(results, key=lambda x: x['overall_score'], reverse=True)[:3], 1):
        print(f"\n   {i}. Żart #{result['joke_id']} ({result['overall_score']:.2f}/10)")
        print(f"      \"{result['text'][:80]}...\"")
        print(f"      Top: {', '.join(result['top3_theories'][:2])}")
    
    print(f"\n📉 Bottom 3 Najsłabsze Żarty:")
    for i, result in enumerate(sorted(results, key=lambda x: x['overall_score'])[:3], 1):
        print(f"\n   {i}. Żart #{result['joke_id']} ({result['overall_score']:.2f}/10)")
        print(f"      \"{result['text'][:80]}...\"")
        print(f"      Top: {', '.join(result['top3_theories'][:2])}")
    
    # Save results
    output_file = Path(__file__).parent / 'validation' / 'test-waldus-classics-results.json'
    output_data = {
        'dataset_name': dataset['dataset_name'],
        'analyzed_at': datetime.now().isoformat(),
        'summary': {
            'total_jokes': len(results),
            'avg_score': avg_score,
            'min_score': min_score,
            'max_score': max_score,
            'expected_match_rate': match_rate,
            'theory_frequency': theory_freq
        },
        'results': results
    }
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)
    
    print(f"\n\n💾 Wyniki zapisane do: {output_file}")
    print(f"\n{'='*80}")
    print("✅ Analiza zakończona!")


if __name__ == "__main__":
    asyncio.run(main())

