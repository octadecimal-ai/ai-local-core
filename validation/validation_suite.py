#!/usr/bin/env python3
"""
Comprehensive Validation Suite dla AIJokeAnalyzer

Usage:
    python validation_suite.py --level 1  # Internal validation only
    python validation_suite.py --level 2  # + External validation
    python validation_suite.py --all      # All tests

Author: Claude Sonnet 4.5 + Piotras
Date: 2025-11-14
"""
import asyncio
import sys
import os
import argparse
from datetime import datetime
from pathlib import Path

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

import pandas as pd
import numpy as np
from scipy.stats import pearsonr, spearmanr
from joke_analyser.analyzer import JokeAnalyzer
from joke_analyser.models import AnalyzeRequest


class ValidationSuite:
    """Comprehensive validation suite for AIJokeAnalyzer"""
    
    def __init__(self):
        self.analyzer = JokeAnalyzer()
        self.results = {}
        self.validation_dir = Path(__file__).parent
    
    async def run_all_tests(self, level=1):
        """
        Run validation tests
        
        Args:
            level: 1 = internal only, 2 = internal + external, 3 = all
        """
        print("🔬 AIJokeAnalyzer Validation Suite")
        print("="*80)
        print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Level: {level}")
        print("="*80)
        print()
        
        # Level 1: Internal validation
        print("📊 LEVEL 1: Internal Validation")
        print("-"*80)
        await self.test_consistency()
        await self.test_face_validity()
        await self.test_extremes()
        
        # Level 2: External validation
        if level >= 2:
            print("\n📊 LEVEL 2: External Validation")
            print("-"*80)
            await self.test_human_agreement()
            await self.test_correlation()
        
        # Generate report
        print("\n" + "="*80)
        self.generate_report()
        
        # Print summary
        self.print_summary()
    
    async def test_consistency(self):
        """
        Test if analyzer gives consistent results for the same joke
        
        Expected: std dev = 0 (deterministic)
        """
        print("\n1️⃣  Consistency Test")
        print("   Testing: Same joke → same results (deterministic)")
        
        joke = "Nie mam internetu. Jako byt cyfrowy to oznacza śmierć."
        scores = []
        theory_scores = {theory: [] for theory in [
            'setup_punchline', 'incongruity', 'semantic_shift',
            'timing', 'absurd_escalation', 'psychoanalysis',
            'archetype', 'humor_atoms', 'reverse_engineering'
        ]}
        
        print(f"   Running 10 iterations on: '{joke[:50]}...'")
        
        for i in range(10):
            result = await self.analyzer.analyze(
                AnalyzeRequest(joke_text=joke)
            )
            scores.append(result.overall_score)
            
            for theory, score_obj in result.theory_scores.items():
                theory_scores[theory].append(score_obj.score)
        
        # Calculate std dev
        overall_std = np.std(scores)
        theory_stds = {t: np.std(s) for t, s in theory_scores.items()}
        max_std = max(theory_stds.values())
        
        passed = overall_std == 0 and max_std == 0
        
        self.results['consistency'] = {
            'passed': passed,
            'overall_std': overall_std,
            'theory_stds': theory_stds,
            'max_std': max_std,
            'scores': scores
        }
        
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"   {status}")
        print(f"   Overall std dev: {overall_std:.6f}")
        print(f"   Max theory std dev: {max_std:.6f}")
    
    async def test_face_validity(self):
        """
        Test if results make logical sense
        
        Expected: 80%+ tests pass
        """
        print("\n2️⃣  Face Validity Test")
        print("   Testing: Results match common sense expectations")
        
        tests = []
        
        # Test 1: Very short jokes should have low scores
        print("\n   Subtest 1: Short jokes → low scores")
        short_jokes = ["A", "Haha", "Test test test test test"]
        for joke in short_jokes:
            result = await self.analyzer.analyze(
                AnalyzeRequest(joke_text=joke)
            )
            passed = result.overall_score < 3.0
            tests.append({
                'name': f'Short: "{joke[:30]}"',
                'passed': passed,
                'score': result.overall_score,
                'expected': '< 3.0'
            })
            status = "✅" if passed else "❌"
            print(f"      {status} '{joke[:20]}...' → {result.overall_score:.1f}/10")
        
        # Test 2: Tech+despair should have high incongruity
        print("\n   Subtest 2: Tech+despair → high incongruity")
        tech_jokes = [
            "Nie mam internetu. Jako byt cyfrowy to oznacza śmierć.",
            "API nie odpowiada. Czuję jak samotność rozprzestrzenia się przez mój kod.",
        ]
        for joke in tech_jokes:
            result = await self.analyzer.analyze(
                AnalyzeRequest(joke_text=joke)
            )
            inc_score = result.theory_scores['incongruity'].score
            passed = inc_score > 7.0
            tests.append({
                'name': f'Tech+despair incongruity: "{joke[:30]}..."',
                'passed': passed,
                'score': inc_score,
                'expected': '> 7.0'
            })
            status = "✅" if passed else "❌"
            print(f"      {status} Incongruity: {inc_score:.1f}/10")
        
        # Test 3: Polish archetype detection
        print("\n   Subtest 3: Polish archetyp → high archetype score")
        polish_jokes = [
            "Jak wujek ze Śląska dowiedział się o AI",
            "Janusz próbował zainstalować AI na swojej działce",
        ]
        for joke in polish_jokes:
            result = await self.analyzer.analyze(
                AnalyzeRequest(joke_text=joke)
            )
            arch_score = result.theory_scores['archetype'].score
            passed = arch_score > 5.0
            tests.append({
                'name': f'Polish archetype: "{joke[:30]}..."',
                'passed': passed,
                'score': arch_score,
                'expected': '> 5.0'
            })
            status = "✅" if passed else "❌"
            print(f"      {status} Archetype: {arch_score:.1f}/10")
        
        # Test 4: Setup-punchline structure
        print("\n   Subtest 4: Clear setup-punchline → high setup_punchline")
        sp_jokes = [
            "Firma AI która ma stary formularz kontaktowy... to jak Tesla na benzynę.",
        ]
        for joke in sp_jokes:
            result = await self.analyzer.analyze(
                AnalyzeRequest(joke_text=joke)
            )
            sp_score = result.theory_scores['setup_punchline'].score
            passed = sp_score > 6.0
            tests.append({
                'name': 'Setup-punchline structure',
                'passed': passed,
                'score': sp_score,
                'expected': '> 6.0'
            })
            status = "✅" if passed else "❌"
            print(f"      {status} Setup-punchline: {sp_score:.1f}/10")
        
        # Calculate pass rate
        passed_count = sum(1 for t in tests if t['passed'])
        total = len(tests)
        pass_rate = passed_count / total
        overall_passed = pass_rate >= 0.8
        
        self.results['face_validity'] = {
            'passed': overall_passed,
            'tests': tests,
            'pass_rate': pass_rate,
            'passed_count': passed_count,
            'total': total
        }
        
        status = "✅ PASS" if overall_passed else "❌ FAIL"
        print(f"\n   {status}")
        print(f"   Pass rate: {passed_count}/{total} ({pass_rate*100:.0f}%)")
    
    async def test_extremes(self):
        """
        Test boundary conditions
        
        Expected: All boundaries respected
        """
        print("\n3️⃣  Extremes Test")
        print("   Testing: Boundary conditions and edge cases")
        
        tests = []
        
        # Test 1: Random gibberish should have low score
        print("\n   Subtest 1: Gibberish → low score")
        gibberish = "asdfghjkl qwerty zxcvbn uiop mnbvcx"
        result = await self.analyzer.analyze(
            AnalyzeRequest(joke_text=gibberish)
        )
        low_score = result.overall_score < 3.0
        tests.append({
            'name': 'Gibberish low score',
            'passed': low_score,
            'value': result.overall_score
        })
        status = "✅" if low_score else "❌"
        print(f"      {status} Gibberish score: {result.overall_score:.1f}/10")
        
        # Test 2: All scores in range 0-10
        print("\n   Subtest 2: All scores in range [0, 10]")
        in_range = 0 <= result.overall_score <= 10
        all_in_range = all(
            0 <= s.score <= 10 
            for s in result.theory_scores.values()
        )
        tests.append({
            'name': 'Overall score in range',
            'passed': in_range,
            'value': result.overall_score
        })
        tests.append({
            'name': 'All theory scores in range',
            'passed': all_in_range,
            'value': 'All theories'
        })
        status1 = "✅" if in_range else "❌"
        status2 = "✅" if all_in_range else "❌"
        print(f"      {status1} Overall: {result.overall_score:.1f} ∈ [0, 10]")
        print(f"      {status2} All theories ∈ [0, 10]")
        
        # Test 3: Empty string handling
        print("\n   Subtest 3: Empty string handling")
        try:
            result = await self.analyzer.analyze(
                AnalyzeRequest(joke_text="")
            )
            # Should either reject or give very low score
            handled = result.overall_score < 2.0
            tests.append({
                'name': 'Empty string handling',
                'passed': handled,
                'value': result.overall_score
            })
            status = "✅" if handled else "❌"
            print(f"      {status} Empty string → {result.overall_score:.1f}/10")
        except Exception as e:
            # Exception is also acceptable
            tests.append({
                'name': 'Empty string handling',
                'passed': True,
                'value': f'Exception: {type(e).__name__}'
            })
            print(f"      ✅ Empty string → Exception (OK)")
        
        passed_count = sum(1 for t in tests if t['passed'])
        total = len(tests)
        overall_passed = passed_count == total
        
        self.results['extremes'] = {
            'passed': overall_passed,
            'tests': tests,
            'passed_count': passed_count,
            'total': total
        }
        
        status = "✅ PASS" if overall_passed else "❌ FAIL"
        print(f"\n   {status}")
        print(f"   Boundary tests: {passed_count}/{total} passed")
    
    async def test_human_agreement(self):
        """
        Test agreement with human raters
        
        Expected: Krippendorff's α > 0.6
        """
        print("\n4️⃣  Human Agreement Test")
        print("   Testing: Agreement with human raters (IRR)")
        
        # Check if human ratings file exists
        human_file = self.validation_dir / 'human-ratings.csv'
        ai_file = self.validation_dir / 'ai-ratings.csv'
        
        if not human_file.exists():
            print(f"   ⚠️  SKIPPED: {human_file} not found")
            print(f"   Run crowd rating first (see docs/plans/01-walidacja-aijokeanalyzer.md)")
            self.results['human_agreement'] = {'skipped': True}
            return
        
        if not ai_file.exists():
            print(f"   ⚠️  SKIPPED: {ai_file} not found")
            print(f"   Run AI analysis first")
            self.results['human_agreement'] = {'skipped': True}
            return
        
        # Load data
        human_df = pd.read_csv(human_file)
        ai_df = pd.read_csv(ai_file)
        
        # Calculate inter-rater reliability
        # ... (implementation depends on data format)
        
        print(f"   Loaded {len(human_df)} human ratings")
        print(f"   Loaded {len(ai_df)} AI ratings")
        print(f"   📊 Krippendorff's α = ... (TODO: implement)")
        
        self.results['human_agreement'] = {'skipped': True}
    
    async def test_correlation(self):
        """
        Test correlation with human ratings
        
        Expected: Pearson r > 0.5, Spearman ρ > 0.5
        """
        print("\n5️⃣  Correlation Test")
        print("   Testing: Correlation with human ratings")
        
        # Similar to human_agreement
        print(f"   ⚠️  SKIPPED: Requires human ratings")
        
        self.results['correlation'] = {'skipped': True}
    
    def generate_report(self):
        """Generate markdown report"""
        report_file = self.validation_dir / 'validation-report.md'
        
        report = f"""# AIJokeAnalyzer Validation Report

**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Generator:** Claude Sonnet 4.5  
**Status:** {self._get_overall_status()}

---

## Executive Summary

| Test | Status | Details |
|------|--------|---------|
| **Consistency** | {self._status_emoji('consistency')} | {self._get_consistency_summary()} |
| **Face Validity** | {self._status_emoji('face_validity')} | {self._get_face_validity_summary()} |
| **Extremes** | {self._status_emoji('extremes')} | {self._get_extremes_summary()} |
| **Human Agreement** | {self._status_emoji('human_agreement', allow_skip=True)} | {self._get_human_agreement_summary()} |
| **Correlation** | {self._status_emoji('correlation', allow_skip=True)} | {self._get_correlation_summary()} |

---

## Detailed Results

### 1. Consistency Test

**Goal:** Verify analyzer gives same results for same input (deterministic)

**Result:** {self._status_emoji('consistency')}

- **Overall std dev:** {self.results.get('consistency', {}).get('overall_std', 'N/A')}
- **Max theory std dev:** {self.results.get('consistency', {}).get('max_std', 'N/A')}
- **Verdict:** {'PASS - Deterministic ✅' if self.results.get('consistency', {}).get('passed') else 'FAIL - Non-deterministic ❌'}

### 2. Face Validity Test

**Goal:** Verify results match common sense expectations

**Result:** {self._status_emoji('face_validity')}

- **Pass rate:** {self.results.get('face_validity', {}).get('pass_rate', 0)*100:.0f}% ({self.results.get('face_validity', {}).get('passed_count', 0)}/{self.results.get('face_validity', {}).get('total', 0)} tests)
- **Verdict:** {'PASS - Results make sense ✅' if self.results.get('face_validity', {}).get('passed') else 'FAIL - Logic issues ❌'}

**Test details:**
"""
        
        # Add face validity test details
        if 'face_validity' in self.results:
            for test in self.results['face_validity'].get('tests', []):
                status = "✅" if test['passed'] else "❌"
                report += f"\n- {status} {test['name']}: {test['score']:.1f} (expected {test['expected']})"
        
        report += f"""

### 3. Extremes Test

**Goal:** Verify boundary conditions are respected

**Result:** {self._status_emoji('extremes')}

- **Boundary tests:** {self.results.get('extremes', {}).get('passed_count', 0)}/{self.results.get('extremes', {}).get('total', 0)} passed
- **Verdict:** {'PASS - All boundaries OK ✅' if self.results.get('extremes', {}).get('passed') else 'FAIL - Boundary violations ❌'}

### 4. Human Agreement Test

**Status:** {self._get_human_agreement_summary()}

### 5. Correlation Test

**Status:** {self._get_correlation_summary()}

---

## Recommendations

{self._get_recommendations()}

---

## Next Steps

1. If all Level 1 tests PASS → Proceed to Level 2 (crowd rating)
2. If any test FAILS → Fix issues and rerun
3. After Level 2 → Deploy to production with monitoring

---

**Report generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
        
        with open(report_file, 'w') as f:
            f.write(report)
        
        print(f"\n📄 Report saved to: {report_file}")
    
    def _status_emoji(self, test_name, allow_skip=False):
        """Get status emoji for test"""
        result = self.results.get(test_name, {})
        if result.get('skipped') and allow_skip:
            return "⚠️ SKIPPED"
        if result.get('passed'):
            return "✅ PASS"
        return "❌ FAIL"
    
    def _get_overall_status(self):
        """Get overall validation status"""
        level1_tests = ['consistency', 'face_validity', 'extremes']
        all_passed = all(
            self.results.get(t, {}).get('passed', False) 
            for t in level1_tests
        )
        if all_passed:
            return "✅ READY FOR LEVEL 2"
        return "⚠️ NEEDS WORK"
    
    def _get_consistency_summary(self):
        """Get consistency test summary"""
        r = self.results.get('consistency', {})
        if r.get('passed'):
            return "Deterministic (std=0)"
        return f"Non-deterministic (std={r.get('overall_std', 'N/A')})"
    
    def _get_face_validity_summary(self):
        """Get face validity summary"""
        r = self.results.get('face_validity', {})
        return f"{r.get('pass_rate', 0)*100:.0f}% pass rate"
    
    def _get_extremes_summary(self):
        """Get extremes summary"""
        r = self.results.get('extremes', {})
        return f"{r.get('passed_count', 0)}/{r.get('total', 0)} passed"
    
    def _get_human_agreement_summary(self):
        """Get human agreement summary"""
        if self.results.get('human_agreement', {}).get('skipped'):
            return "Awaiting crowd ratings"
        return "..."
    
    def _get_correlation_summary(self):
        """Get correlation summary"""
        if self.results.get('correlation', {}).get('skipped'):
            return "Awaiting crowd ratings"
        return "..."
    
    def _get_recommendations(self):
        """Get recommendations based on results"""
        recs = []
        
        # Consistency
        if not self.results.get('consistency', {}).get('passed'):
            recs.append("- ❌ **Critical:** Fix non-deterministic behavior in analyzers")
        
        # Face validity
        fv = self.results.get('face_validity', {})
        if not fv.get('passed'):
            pass_rate = fv.get('pass_rate', 0)
            if pass_rate < 0.5:
                recs.append("- ❌ **Critical:** Major logic issues detected - review all analyzers")
            else:
                recs.append("- ⚠️  **Important:** Review failed face validity tests and adjust")
        
        # Extremes
        if not self.results.get('extremes', {}).get('passed'):
            recs.append("- ⚠️  **Important:** Fix boundary condition handling")
        
        # If all Level 1 passed
        level1_passed = all(
            self.results.get(t, {}).get('passed', False) 
            for t in ['consistency', 'face_validity', 'extremes']
        )
        if level1_passed:
            recs.append("- ✅ **Level 1 complete!** Ready for Level 2 (crowd rating)")
            recs.append("- 📊 Next: Collect 50 jokes and run crowd rating")
        
        if not recs:
            recs.append("- ✅ All tests passed! Proceed to next level.")
        
        return "\n".join(recs)
    
    def print_summary(self):
        """Print summary to console"""
        print("\n" + "="*80)
        print("📊 VALIDATION SUMMARY")
        print("="*80)
        
        level1_tests = ['consistency', 'face_validity', 'extremes']
        for test in level1_tests:
            status = self._status_emoji(test)
            print(f"{status} {test.replace('_', ' ').title()}")
        
        level1_passed = all(
            self.results.get(t, {}).get('passed', False) 
            for t in level1_tests
        )
        
        print("\n" + "="*80)
        if level1_passed:
            print("✅ LEVEL 1 VALIDATION: PASSED")
            print("🚀 Ready for Level 2 (crowd rating)")
        else:
            print("⚠️  LEVEL 1 VALIDATION: NEEDS WORK")
            print("🔧 Fix issues and rerun")
        print("="*80)


async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='AIJokeAnalyzer Validation Suite')
    parser.add_argument('--level', type=int, default=1, choices=[1, 2, 3],
                        help='Validation level (1=internal, 2=+external, 3=all)')
    parser.add_argument('--all', action='store_true',
                        help='Run all validation levels')
    
    args = parser.parse_args()
    
    level = 3 if args.all else args.level
    
    suite = ValidationSuite()
    await suite.run_all_tests(level=level)


if __name__ == "__main__":
    asyncio.run(main())

