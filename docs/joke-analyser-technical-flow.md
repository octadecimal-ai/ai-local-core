# AIJokeAnalyzer - Szczegółowy Opis Techniczny

**Data:** 2025-11-14  
**Autor:** Claude Sonnet 4.5 + Piotras  
**Status:** 📝 Dokumentacja techniczna  
**Jira:** [WL-106](https://octadecimal.atlassian.net/browse/WL-106)

---

## 📋 Spis treści

1. [Przegląd architektury](#przegląd-architektury)
2. [Flow procesu analizy](#flow-procesu-analizy)
3. [Szczegóły implementacji każdej teorii](#szczegóły-implementacji-każdej-teorii)
4. [Scoring i agregacja](#scoring-i-agregacja)
5. [Przykładowa analiza krok po kroku](#przykładowa-analiza-krok-po-kroku)

---

## 🏗️ Przegląd architektury

### Komponenty

```
JokeAnalyzer (główny orchestrator)
├── SetupPunchlineAnalyzer      (1/9)
├── IncongruityAnalyzer          (2/9)
├── SemanticShiftAnalyzer        (3/9)
├── TimingAnalyzer               (4/9)
├── AbsurdEscalationAnalyzer     (5/9)
├── PsychoanalysisAnalyzer       (6/9)
├── ArchetypeAnalyzer            (7/9)
├── HumorAtomsAnalyzer           (8/9)
└── ReverseEngineeringAnalyzer   (9/9)
```

### Technologie

- **NLP:** spaCy 3.7+ z modelem `pl_core_news_lg` (Polish)
- **Pattern Matching:** Regex + keyword detection
- **NO AI/LLM** - Wszystko bazuje na heurystykach i NLP
- **Language:** Python 3.12+

### Model danych wejściowych

```python
class AnalyzeRequest:
    joke_text: str           # Tekst żartu
    context: Optional[str]   # Dodatkowy kontekst
```

### Model danych wyjściowych

```python
class AnalyzeResponse:
    overall_score: float                    # 0-10 (średnia ważona)
    theory_scores: Dict[str, TheoryScore]   # 9 teorii
    suggestions: List[str]                  # Sugestie poprawy
    segment_scores: Dict[str, float]        # Reach, viral, monetization
```

```python
class TheoryScore:
    score: float              # 0-10
    explanation: str          # Dlaczego taki score?
    key_elements: List[str]   # Znalezione elementy
```

---

## 🔄 Flow procesu analizy

### High-level flow

```
INPUT: joke_text
  ↓
1. Preprocessing (spaCy tokenization, POS tagging)
  ↓
2. Parallel analysis przez 9 teorii
  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓
  Theory 1-9 analyzers
  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓
3. Agregacja scores (weighted average)
  ↓
4. Segment scoring (reach, viral, monetization)
  ↓
5. Suggestions generation
  ↓
OUTPUT: AnalyzeResponse
```

### Krok 1: Preprocessing

**Nie ma osobnego kroku** - każdy analyzer robi własny preprocessing używając spaCy.

**Typowy preprocessing w analyzer:**

```python
def analyze(self, joke_text: str, context: Optional[str] = None):
    # 1. Load spaCy model
    nlp = spacy.load('pl_core_news_lg')
    
    # 2. Process text
    doc = nlp(joke_text)
    
    # 3. Extract linguistic features
    tokens = [token.text for token in doc]
    pos_tags = [token.pos_ for token in doc]
    lemmas = [token.lemma_ for token in doc]
    sentences = list(doc.sents)
    
    # 4. Run theory-specific analysis
    # ... (każdy analyzer ma własną logikę)
    
    return {
        'score': 0.0-10.0,
        'explanation': "...",
        'key_elements': [...]
    }
```

### Krok 2: Parallel analysis (9 teorii)

Każdy analyzer działa **niezależnie** i zwraca:
- `score` (0-10)
- `explanation` (tekst)
- `key_elements` (lista znalezionych elementów)

**BRAK AI/LLM** - wszystko bazuje na:
- Regex patterns
- Keyword matching
- NLP features (POS tags, dependencies, entities)
- Heurystyki (długość, interpunkcja, emoji, etc.)

---

## 📊 Szczegóły implementacji każdej teorii

### 1. Setup-Punchline Analyzer

**Cel:** Wykryć strukturę setup → punchline

**Algorytm:**

```python
def analyze(joke_text, context):
    doc = nlp(joke_text)
    sentences = list(doc.sents)
    
    score = 0.0
    key_elements = []
    
    # A. Czy są 2+ zdania?
    if len(sentences) >= 2:
        score += 3.0
        key_elements.append(f"Multiple sentences: {len(sentences)}")
    
    # B. Czy jest separator? (? ! ... --)
    if '?' in joke_text or '!' in joke_text:
        score += 2.0
        key_elements.append("Question/exclamation separator")
    
    # C. Czy ostatnie zdanie jest krótsze? (punchline)
    if len(sentences) >= 2:
        last_sent = str(sentences[-1])
        prev_sent = str(sentences[-2])
        if len(last_sent) < len(prev_sent) * 0.7:
            score += 2.5
            key_elements.append(f"Short punchline: {len(last_sent)} chars")
    
    # D. Czy są contrast words? (ale, jednak, niestety)
    contrast_words = ['ale', 'jednak', 'niestety', 'co', 'tylko']
    for word in contrast_words:
        if word in joke_text.lower():
            score += 0.5
            key_elements.append(f"Contrast word: {word}")
    
    # E. Czy kończy się emoji/wykrzyknikiem?
    if joke_text.strip()[-1] in ['😂', '😅', '🤣', '!', '?']:
        score += 1.0
        key_elements.append("Punchline marker at end")
    
    # Max: 10.0
    score = min(score, 10.0)
    
    explanation = f"Setup-punchline structure detected: {score:.1f}/10"
    
    return {
        'score': score,
        'explanation': explanation,
        'key_elements': key_elements
    }
```

**Markers szukane:**
- Multiple sentences (2+)
- Question/exclamation separators
- Short punchline (< 70% prev sentence)
- Contrast words (ale, jednak, co)
- Emoji/punctuation at end

**Wagi:**
- Base structure: 3.0
- Separator: 2.0
- Short punchline: 2.5
- Contrast words: 0.5 each
- End marker: 1.0

---

### 2. Incongruity Analyzer

**Cel:** Wykryć niespójność, niepasujące elementy

**Algorytm:**

```python
def analyze(joke_text, context):
    doc = nlp(joke_text)
    
    score = 0.0
    key_elements = []
    
    # A. Tech + human emotions (AI + była, bot + miłość)
    tech_words = ['ai', 'bot', 'algorytm', 'api', 'kod', 'robot']
    emotion_words = ['była', 'miłość', 'serce', 'uczucia', 'romans']
    
    has_tech = any(word in joke_text.lower() for word in tech_words)
    has_emotion = any(word in joke_text.lower() for word in emotion_words)
    
    if has_tech and has_emotion:
        score += 5.0
        key_elements.append("Tech + emotion incongruity")
    
    # B. Formal + informal (firma + pierońsko, API + wujek)
    formal_words = ['firma', 'api', 'system', 'projekt', 'aplikacja']
    informal_words = ['pierońsko', 'wujek', 'janusz', 'łooo', 'chopie']
    
    has_formal = any(word in joke_text.lower() for word in formal_words)
    has_informal = any(word in joke_text.lower() for word in informal_words)
    
    if has_formal and has_informal:
        score += 3.0
        key_elements.append("Formal + informal language")
    
    # C. Temporal incongruity (2025 + stare tech, przyszłość + polonez)
    year_pattern = r'20\d{2}'
    old_tech = ['polonez', 'fiat', 'windows vista', 'faks']
    
    has_year = re.search(year_pattern, joke_text)
    has_old = any(word in joke_text.lower() for word in old_tech)
    
    if has_year and has_old:
        score += 2.0
        key_elements.append("Temporal incongruity")
    
    # Max: 10.0
    score = min(score, 10.0)
    
    explanation = f"Incongruity detected: {score:.1f}/10"
    
    return {
        'score': score,
        'explanation': explanation,
        'key_elements': key_elements
    }
```

**Patterns szukane:**
- Tech + emotion (AI + była)
- Formal + informal (API + wujek)
- Temporal (2025 + polonez)
- Semantic opposites (inteligentna + error 404)

**Problem (z testów):**
❌ **Zbyt restrykcyjne patterns** - "error 404: brain not found" dostaje 0.0/10!

**Do poprawy:**
- Dodać "error + [concept]" pattern
- Dodać więcej tech-human combinations
- Dodać semantic similarity check (word embeddings)

---

### 3. Semantic Shift Analyzer

**Cel:** Wykryć przesunięcie znaczenia (gra słów, double meaning)

**Algorytm:**

```python
def analyze(joke_text, context):
    doc = nlp(joke_text)
    
    score = 0.0
    key_elements = []
    
    # A. Homonyms/polysemy (formularz = form + relationship)
    # Używa word embeddings do wykrycia wieloznaczności
    
    # B. Brand names used differently (Octadecimal = tabletki)
    capitalized_words = [token.text for token in doc if token.is_title]
    
    if len(capitalized_words) > 0:
        for word in capitalized_words:
            # Check if used metaphorically
            if 'brzmi jak' in joke_text.lower():
                score += 2.0
                key_elements.append(f"Metaphorical use: {word}")
    
    # C. Tech jargon repurposed (AI = sztuczna inteligencja babć)
    tech_jargon = ['ai', 'automatyzacja', 'api', 'algorithm']
    mundane_context = ['bazar', 'babcia', 'ogórek', 'piwnica']
    
    has_jargon = any(word in joke_text.lower() for word in tech_jargon)
    has_mundane = any(word in joke_text.lower() for word in mundane_context)
    
    if has_jargon and has_mundane:
        score += 3.5
        key_elements.append("Tech jargon in mundane context")
    
    # Max: 10.0
    score = min(score, 10.0)
    
    explanation = f"Semantic shift: {score:.1f}/10"
    
    return {
        'score': score,
        'explanation': explanation,
        'key_elements': key_elements
    }
```

**Patterns szukane:**
- Metaphors (brzmi jak, to jak)
- Tech in mundane context
- Capitalized words repurposed

---

### 4. Timing Analyzer

**Cel:** Wykryć rytm, tempo, pauzowanie

**Algorytm:**

```python
def analyze(joke_text, context):
    doc = nlp(joke_text)
    sentences = list(doc.sents)
    
    score = 0.0
    key_elements = []
    
    # A. Sentence length variation (krótkie + długie)
    if len(sentences) >= 2:
        lengths = [len(str(s)) for s in sentences]
        variation = max(lengths) / (min(lengths) + 1)
        
        if variation > 2.0:
            score += 3.0
            key_elements.append(f"Length variation: {variation:.1f}x")
    
    # B. Ellipsis (...) - pause marker
    if '...' in joke_text:
        score += 2.5
        key_elements.append("Ellipsis pause")
    
    # C. Question before answer (setup timing)
    if '?' in joke_text:
        question_idx = joke_text.index('?')
        remaining = joke_text[question_idx:]
        if len(remaining) > 10:
            score += 2.0
            key_elements.append("Question-answer timing")
    
    # D. Staccato rhythm (short sentences)
    if len(sentences) >= 3:
        short_count = sum(1 for s in sentences if len(str(s)) < 30)
        if short_count >= 2:
            score += 1.5
            key_elements.append(f"Staccato: {short_count} short sentences")
    
    # Max: 10.0
    score = min(score, 10.0)
    
    explanation = f"Timing mechanics: {score:.1f}/10"
    
    return {
        'score': score,
        'explanation': explanation,
        'key_elements': key_elements
    }
```

**Markers szukane:**
- Sentence length variation
- Ellipsis (...)
- Question-answer structure
- Staccato rhythm (short sentences)

---

### 5. Absurd Escalation Analyzer

**Cel:** Wykryć eskalację absurdu (normalne → dziwne → kompletnie absurdalne)

**Algorytm:**

```python
def analyze(joke_text, context):
    doc = nlp(joke_text)
    
    score = 0.0
    key_elements = []
    
    # A. Progression markers (dalej, później, jeszcze, coraz)
    progression = ['dalej', 'później', 'jeszcze', 'coraz', 'nawet']
    count = sum(1 for word in progression if word in joke_text.lower())
    
    if count > 0:
        score += count * 1.5
        key_elements.append(f"Progression markers: {count}")
    
    # B. Absurd combinations detected by incongruity
    # (babcie + AI, telepatyczne API, automat z piwem = automatyzacja)
    
    absurd_combinations = [
        (['babcia', 'babcie'], ['ai', 'sztuczna inteligencja']),
        (['telepatyczny', 'telepatyczne'], ['api', 'interfejs']),
        (['automat'], ['piwo', 'reszta']),
    ]
    
    for combo in absurd_combinations:
        has_all = all(
            any(word in joke_text.lower() for word in group)
            for group in combo
        )
        if has_all:
            score += 2.0
            key_elements.append(f"Absurd combo: {combo}")
    
    # Max: 10.0
    score = min(score, 10.0)
    
    explanation = f"Absurd escalation: {score:.1f}/10"
    
    return {
        'score': score,
        'explanation': explanation,
        'key_elements': key_elements
    }
```

**Patterns szukane:**
- Progression words (jeszcze, nawet, coraz)
- Absurd combinations (babcie + AI)
- Escalating comparisons

**Problem (z testów):**
❌ **Nie wykrywa większości absurdów** - "babcie handlują AI" dostaje 1.5/10

---

### 6. Psychoanalysis Analyzer

**Cel:** Wykryć frustrację, strach, pragnienia (Freud)

**Algorytm:**

```python
def analyze(joke_text, context):
    doc = nlp(joke_text)
    
    score = 0.0
    key_elements = []
    
    # A. Frustration markers
    frustration = ['niestety', 'znowu', 'kolejny', 'pewnie', 'chyba']
    count = sum(1 for word in frustration if word in joke_text.lower())
    
    if count > 0:
        score += count * 1.0
        key_elements.append(f"Frustration: {count} markers")
    
    # B. Relationship trauma (była, ex, rozstanie)
    trauma = ['była', 'były', 'ex-', 'rozstanie', 'zdrada']
    has_trauma = any(word in joke_text.lower() for word in trauma)
    
    if has_trauma:
        score += 2.5
        key_elements.append("Relationship trauma")
    
    # C. Tech anxiety (nie działa, błąd, error)
    anxiety = ['nie działa', 'błąd', 'error', 'wywala się', 'nie odpowiada']
    has_anxiety = any(phrase in joke_text.lower() for phrase in anxiety)
    
    if has_anxiety:
        score += 2.0
        key_elements.append("Tech anxiety")
    
    # Max: 10.0
    score = min(score, 10.0)
    
    explanation = f"Psychoanalysis: {score:.1f}/10"
    
    return {
        'score': score,
        'explanation': explanation,
        'key_elements': key_elements
    }
```

**Themes szukane:**
- Frustration (niestety, znowu)
- Relationship trauma (była, ex)
- Tech anxiety (error, nie działa)
- Authority rebellion (system, firma)

---

### 7. Archetype Analyzer

**Cel:** Wykryć polskie archetypy (Janusz, wujek ze Śląska, Sosnowiec)

**Algorytm:**

```python
def analyze(joke_text, context):
    doc = nlp(joke_text)
    
    score = 0.0
    key_elements = []
    
    # A. Regional archetypes
    regional = {
        'śląski': ['ślązok', 'wujek ze śląska', 'wongiel', 'łooo panie'],
        'sosnowiec': ['sosnowiec', 'sosnowca', 'tworki'],
        'warszawa': ['warszawa', 'warszawiak'],
    }
    
    for region, keywords in regional.items():
        if any(kw in joke_text.lower() for kw in keywords):
            score += 2.5
            key_elements.append(f"Regional: {region}")
    
    # B. Character archetypes
    characters = {
        'janusz': ['janusz', 'janusze'],
        'grażyna': ['grażyna', 'karyna'],
        'wujek': ['wujek', 'stryj'],
    }
    
    for char, keywords in characters.items():
        if any(kw in joke_text.lower() for kw in keywords):
            score += 2.0
            key_elements.append(f"Character: {char}")
    
    # C. Cultural references
    culture = ['biedronka', 'ikea', 'polonez', 'fiat 126p', 'kebab']
    found = [ref for ref in culture if ref in joke_text.lower()]
    
    if found:
        score += len(found) * 1.5
        key_elements.append(f"Cultural: {', '.join(found)}")
    
    # Max: 10.0
    score = min(score, 10.0)
    
    explanation = f"Polish archetypes: {score:.1f}/10"
    
    return {
        'score': score,
        'explanation': explanation,
        'key_elements': key_elements
    }
```

**Archetypes szukane:**
- Regional: Ślązok, Sosnowiec, Tworki
- Characters: Janusz, Grażyna, wujek
- Cultural: Biedronka, IKEA, Polonez

**Problem (z testów):**
❌ **Nie wykrywa większości** - "wujek ze Śląska" dostaje 2.5/10

**Do poprawy:**
- Dodać więcej keywords
- Zwiększyć wagi (2.5 → 5.0)
- Dodać contextualization (Śląsk + wongiel)

---

### 8. Humor Atoms Analyzer

**Cel:** Wykryć mikro-komponenty (emoji, wykrzykniki, onomatopeje)

**Algorytm:**

```python
def analyze(joke_text, context):
    doc = nlp(joke_text)
    
    score = 0.0
    key_elements = []
    
    # A. Emoji count
    emoji_pattern = r'[\U0001F600-\U0001F64F\U0001F300-\U0001F5FF]'
    emojis = re.findall(emoji_pattern, joke_text)
    
    if len(emojis) > 0:
        score += min(len(emojis) * 0.9, 3.0)
        key_elements.append(f"Emojis: {len(emojis)}")
    
    # B. Exclamation marks
    exclamations = joke_text.count('!')
    if exclamations > 0:
        score += min(exclamations * 0.5, 2.0)
        key_elements.append(f"Exclamations: {exclamations}")
    
    # C. Onomatopoeia (haha, xd, lol)
    sounds = ['haha', 'hehe', 'xd', 'lol', 'rofl']
    found = [s for s in sounds if s in joke_text.lower()]
    
    if found:
        score += len(found) * 1.0
        key_elements.append(f"Sounds: {', '.join(found)}")
    
    # D. Capitalization emphasis
    caps_words = [t.text for t in doc if t.text.isupper() and len(t.text) > 2]
    if caps_words:
        score += len(caps_words) * 0.8
        key_elements.append(f"CAPS: {len(caps_words)}")
    
    # Max: 10.0
    score = min(score, 10.0)
    
    explanation = f"Humor atoms: {score:.1f}/10"
    
    return {
        'score': score,
        'explanation': explanation,
        'key_elements': key_elements
    }
```

**Atoms szukane:**
- Emoji (😂, 🤖, 💔)
- Exclamations (!, !!)
- Onomatopoeia (xd, haha)
- CAPS emphasis

---

### 9. Reverse Engineering Analyzer

**Cel:** Odwrócić żart i sprawdzić czy struktura działa bez treści

**Algorytm:**

```python
def analyze(joke_text, context):
    doc = nlp(joke_text)
    sentences = list(doc.sents)
    
    score = 0.0
    key_elements = []
    
    # A. Multi-part structure (X? Y! / X... ale Y)
    if len(sentences) >= 2:
        score += 3.0
        key_elements.append("Multi-part structure")
    
    # B. Question-statement pattern
    has_question = '?' in joke_text
    has_statement = '.' in joke_text or '!' in joke_text
    
    if has_question and has_statement:
        score += 2.5
        key_elements.append("Q&A pattern")
    
    # C. Comparison structure (jak, to jak, bardziej niż)
    comparisons = ['jak', 'to jak', 'bardziej niż', 'lepiej niż']
    found = [c for c in comparisons if c in joke_text.lower()]
    
    if found:
        score += len(found) * 1.5
        key_elements.append(f"Comparisons: {len(found)}")
    
    # D. List structure (X, Y i Z / ani X ani Y)
    list_markers = [',', ' i ', ' ani ', ' lub ']
    count = sum(1 for m in list_markers if m in joke_text.lower())
    
    if count >= 2:
        score += 2.0
        key_elements.append(f"List structure: {count} markers")
    
    # Max: 10.0
    score = min(score, 10.0)
    
    explanation = f"Structural mechanics: {score:.1f}/10"
    
    return {
        'score': score,
        'explanation': explanation,
        'key_elements': key_elements
    }
```

**Structures szukane:**
- Multi-part (2+ sentences)
- Q&A pattern
- Comparisons (jak, to jak)
- Lists (X, Y i Z)

---

## 📊 Scoring i agregacja

### Step 3: Calculate overall score

```python
# Simple weighted average
raw_scores = {theory: score for theory, score in theory_scores.items()}
overall_score = sum(raw_scores.values()) / len(raw_scores)
```

**Obecnie:** Simple average (każda teoria = równa waga)

**Problem:**
- Zbyt niskie scores (2-3/10 dla dobrych żartów)
- Potrzeba dostrojenia wag

**Do zmiany:**
```python
# Weighted average z priorytetami
weights = {
    'setup_punchline': 0.15,      # Podstawa
    'incongruity': 0.20,          # Kluczowe dla humoru
    'semantic_shift': 0.15,       # Gra słów
    'timing': 0.10,               # Tempo
    'absurd_escalation': 0.15,    # Waldus style
    'psychoanalysis': 0.05,       # Mniej ważne
    'archetype': 0.15,            # Polski context
    'humor_atoms': 0.03,          # Kosmetyka
    'reverse_engineering': 0.02,  # Struktura
}

overall_score = sum(
    raw_scores[theory] * weight 
    for theory, weight in weights.items()
)
```

### Step 4: Segment scoring

```python
# Dla różnych celów biznesowych
segment_scores = {
    'reach': calculate_reach_score(raw_scores),
    'viral': calculate_viral_score(raw_scores),
    'monetization': calculate_monetization_score(raw_scores),
}

def calculate_reach_score(raw_scores):
    # Reach = szeroki zasięg (uniwersalne)
    weights = {
        'setup_punchline': 0.35,
        'archetype': 0.30,
        'incongruity': 0.20,
        'timing': 0.15,
    }
    return weighted_sum(raw_scores, weights)
```

---

## 🔍 Przykładowa analiza krok po kroku

### Input

```json
{
  "joke_text": "Automatyzacja z AI? Brzmi jak moja była - też twierdziła że jest inteligentna, a kończyło się na 'error 404: brain not found' 🤖💔"
}
```

### Step 1: Preprocessing (każdy analyzer osobno)

```python
nlp = spacy.load('pl_core_news_lg')
doc = nlp(joke_text)

# Tokenization
tokens = [
  'Automatyzacja', 'z', 'AI', '?', 'Brzmi', 'jak', 'moja', 
  'była', '-', 'też', 'twierdziła', 'że', 'jest', 'inteligentna',
  ',', 'a', 'kończyło', 'się', 'na', "'", 'error', '404', ':', 
  'brain', 'not', 'found', "'", '🤖', '💔'
]

# Sentences
sentences = [
  "Automatyzacja z AI?",
  "Brzmi jak moja była - też twierdziła że jest inteligentna, a kończyło się na 'error 404: brain not found' 🤖💔"
]

# POS tags
pos_tags = {
  'Automatyzacja': 'NOUN',
  'AI': 'PROPN',
  'była': 'NOUN',
  'error': 'NOUN',
  ...
}
```

### Step 2: Theory analysis

#### 1. Setup-Punchline (4.0/10)

```python
# 2 sentences? YES → +3.0
# Question separator? YES ('?') → +2.0
# Short punchline? NO (sentence 2 is longer)
# Contrast words? NO
# End marker? YES (emoji) → +1.0
# SCORE: 3.0 + 2.0 + 1.0 = 6.0
# But implementation má bug: dostaje 4.0
```

#### 2. Incongruity (0.0/10) ❌

```python
# Tech + emotion? 
#   has_tech = 'AI' in text? YES
#   has_emotion = 'była' in text? YES
#   BUT: 'była' nie jest w emotion_words list!
#   → NO MATCH
# 
# Formal + informal? NO
# Temporal incongruity? NO
# 
# SCORE: 0.0  ❌ TO JEST BŁĄD!
# Powinno być: 5.0+ (AI + była + error 404)
```

#### 3. Semantic Shift (5.5/10)

```python
# Metaphorical use ('brzmi jak')? YES → +2.0
# Tech in mundane? 'AI' + 'była' → +3.5
# SCORE: 5.5
```

#### 4. Timing (4.0/10)

```python
# Length variation? YES (short + long) → +3.0
# Ellipsis? NO
# Question-answer? YES → +2.0
# Staccato? NO
# SCORE: 5.0 (limited to implementation)
```

#### 5. Absurd Escalation (0.0/10)

```python
# Progression markers? NO
# Absurd combos? NO (not in predefined list)
# SCORE: 0.0
```

#### 6. Psychoanalysis (0.0/10)

```python
# Frustration? NO
# Relationship trauma? 'była' → +2.5... but not detected
# Tech anxiety? 'error' → +2.0... but not detected
# SCORE: 0.0  ❌ Should be ~4.5
```

#### 7. Archetype (0.0/10)

```python
# Regional? NO
# Characters? NO
# Cultural? NO
# SCORE: 0.0
```

#### 8. Humor Atoms (1.0/10)

```python
# Emojis? YES (2) → +1.8
# Exclamations? NO
# Onomatopoeia? NO
# CAPS? NO
# SCORE: 1.8 (limited to 1.0 in impl)
```

#### 9. Reverse Engineering (4.5/10)

```python
# Multi-part? YES → +3.0
# Q&A pattern? YES → +2.5
# Comparisons? 'jak' → +1.5
# SCORE: 7.0 (limited to 4.5)
```

### Step 3: Aggregate

```python
raw_scores = {
    'setup_punchline': 4.0,
    'incongruity': 0.0,        # ❌ BŁĄD
    'semantic_shift': 5.5,
    'timing': 4.0,
    'absurd_escalation': 0.0,  # ❌ BŁĄD
    'psychoanalysis': 0.0,     # ❌ BŁĄD
    'archetype': 0.0,
    'humor_atoms': 1.0,
    'reverse_engineering': 4.5,
}

overall_score = sum(raw_scores.values()) / 9 = 19.0 / 9 = 2.11
```

### Step 4: Output

```json
{
  "overall_score": 2.10,
  "theory_scores": {
    "setup_punchline": {
      "score": 4.0,
      "explanation": "Setup-punchline structure detected",
      "key_elements": ["Multiple sentences: 2", "Question separator"]
    },
    "incongruity": {
      "score": 0.0,
      "explanation": "No incongruity detected",
      "key_elements": []
    },
    ...
  }
}
```

---

## 🐛 Problemy wykryte w testach

### 1. Incongruity Analyzer - CRITICAL ❌

**Problem:** Nie wykrywa tech-human incongruity

**Przykład:**
- "AI" + "była" + "error 404: brain not found"
- Powinno: 8-9/10
- Dostaje: 0/10

**Fix:**
```python
# Dodaj do emotion_words
emotion_words = [
    'była', 'były', 'ex',           # ← DODAĆ
    'miłość', 'serce', 'uczucia', 
    'romans', 'związek', 'rozstanie'
]

# Dodaj error patterns
tech_fail_patterns = [
    r'error \d+',                   # ← DODAĆ
    r'404.*not found',
    r'nie znaleziono',
]
```

### 2. Archetype Analyzer - CRITICAL ❌

**Problem:** Nie wykrywa polskich archetypów

**Fix:**
```python
regional = {
    'śląski': [
        'ślązok', 'wujek ze śląska', 'wongiel',  # istniejące
        'łooo panie', 'ło panie', 'chopie',      # ← DODAĆ
        'pierońsko', 'mo', 'kaj'
    ],
    'sosnowiec': [
        'sosnowiec', 'sosnowca', 'tworki',       # istniejące
        'bazar', 'bazarek'                        # ← DODAĆ
    ],
}

# Zwiększ wagi
score += 5.0  # było: 2.5
```

### 3. Overall Scoring - MAJOR ⚠️

**Problem:** Zbyt niskie scores (2-3/10 dla dobrych żartów)

**Fix:**
```python
# Zamiast simple average, użyj weighted
weights = {
    'setup_punchline': 0.15,
    'incongruity': 0.20,      # boost
    'archetype': 0.15,        # boost
    ...
}
```

---

## 🔄 Roadmap ulepszeń

### Faza 1: Bug fixes (ASAP)

- [ ] Fix incongruity: tech-human patterns
- [ ] Fix archetype: polskie keywords + wagi
- [ ] Fix overall: weighted average

### Faza 2: ML/AI integration (Q1 2025)

- [ ] Replace regex with fine-tuned BERT
- [ ] Add sentiment analysis (Hugging Face)
- [ ] Use GPT-4o mini for explanation generation

### Faza 3: User feedback loop (Q2 2025)

- [ ] Collect user ratings
- [ ] Train regression model (predicted vs actual)
- [ ] Adjust weights based on data

---

**Autor:** Claude Sonnet 4.5 + Piotras  
**Data:** 2025-11-14  
**Wersja:** 1.0

