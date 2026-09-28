import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../engine/ol_chiki_transliteration.dart';

// ---------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------

class PhraseEntry {
  final String hindi; // normalized
  final String santali;
  final bool verified;

  PhraseEntry({required this.hindi, required this.santali, this.verified = false});
}

// ---------------------------------------------------------------------
// Normalization -- keep this consistent everywhere or lookups silently miss.
// ---------------------------------------------------------------------

class Normalizer {
  static final _punct = RegExp(r'[।?!.,;:॥]');

  static String normalize(String text) {
    return text
        .replaceAll(_punct, '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<String> tokenize(String normalizedText) {
    if (normalizedText.isEmpty) return [];
    return normalizedText.split(' ');
  }
}

// ---------------------------------------------------------------------
// Dictionary: loads TSV & JSON schemas across Web & Native
// ---------------------------------------------------------------------

class PhraseDictionary {
  final Map<String, PhraseEntry> exactSentenceMap = {}; // full-sentence key
  final Map<String, PhraseEntry> phraseMap = {}; // any-length phrase key
  final Map<String, String> reverseExactMap = {}; // santali -> hindi
  final Map<String, String> reversePhraseMap = {}; // santali -> hindi
  int maxPhraseLenWords = 1;

  /// In-memory direct loading for Map/JSON datasets fallback
  void addEntryDirect({required String hindi, required String santali, bool verified = true}) {
    final hindiNorm = Normalizer.normalize(hindi);
    final santaliTrim = santali.trim();
    if (hindiNorm.isEmpty || santaliTrim.isEmpty) return;

    final entry = PhraseEntry(hindi: hindiNorm, santali: santaliTrim, verified: verified);
    exactSentenceMap[hindiNorm] = entry;
    phraseMap[hindiNorm] = entry;

    final santaliNorm = Normalizer.normalize(santaliTrim);
    if (santaliNorm.isNotEmpty) {
      reverseExactMap[santaliNorm] = hindi;
      reversePhraseMap[santaliNorm] = hindi;
    }
    reverseExactMap[santaliTrim] = hindi;

    final devanagariSantali = OlChikiTransliteration.toDevanagari(santaliTrim);
    final devNorm = Normalizer.normalize(devanagariSantali);
    if (devNorm.isNotEmpty && devNorm != santaliNorm) {
      reverseExactMap[devNorm] = hindi;
      reversePhraseMap[devNorm] = hindi;
    }
    if (devanagariSantali.trim().isNotEmpty) {
      reverseExactMap[devanagariSantali.trim()] = hindi;
    }

    final wordCount = Normalizer.tokenize(hindiNorm).length;
    if (wordCount > maxPhraseLenWords) maxPhraseLenWords = wordCount;
  }

  /// Parses raw TSV text string directly (works on Web & Native via rootBundle)
  void loadTsvContent(String content) {
    if (content.trim().isEmpty) return;
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) return;

    final header = lines.first.split('\t').map((h) => h.trim().toLowerCase()).toList();
    final hindiCol = header.indexOf('hindi');
    int santaliCol = header.indexOf('santali');
    if (santaliCol == -1) santaliCol = header.indexOf('santali_olchiki');
    if (santaliCol == -1) santaliCol = header.indexOf('santhali');
    final verifiedCol = header.indexOf('verification_status');

    if (hindiCol == -1 || santaliCol == -1) {
      return;
    }

    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final cols = line.split('\t');
      if (cols.length <= hindiCol || cols.length <= santaliCol) continue;

      final hindiNorm = Normalizer.normalize(cols[hindiCol]);
      final santali = cols[santaliCol].trim();
      if (hindiNorm.isEmpty || santali.isEmpty) continue;

      final verified = verifiedCol != -1 &&
          cols.length > verifiedCol &&
          cols[verifiedCol].trim().toLowerCase().contains('verified');

      addEntryDirect(hindi: hindiNorm, santali: santali, verified: verified);
    }
  }

  /// Parses raw JSON text string directly
  void loadJsonContent(String jsonStr) {
    if (jsonStr.trim().isEmpty) return;
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        // Load POS Lexicon sections from santhali_grammar_pos_lexicon.json
        for (final posKey in ['pronouns', 'postpositions', 'verbs', 'adverbs_adjectives', 'negation', 'classroom_idioms']) {
          if (decoded.containsKey(posKey) && decoded[posKey] is Map<String, dynamic>) {
            final posMap = decoded[posKey] as Map<String, dynamic>;
            for (final entry in posMap.entries) {
              addEntryDirect(hindi: entry.key, santali: entry.value.toString(), verified: true);
            }
          }
        }
        if (decoded.containsKey('word_dictionary')) {
          final dictMap = decoded['word_dictionary'] as Map<String, dynamic>;
          for (final entry in dictMap.entries) {
            addEntryDirect(hindi: entry.key, santali: entry.value.toString());
          }
        }
        if (decoded.containsKey('parallel_corpus')) {
          final list = decoded['parallel_corpus'] as List<dynamic>;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final h = item['hindi']?.toString();
              final s = item['tribal']?.toString() ?? item['santhali']?.toString();
              if (h != null && s != null) {
                addEntryDirect(hindi: h, santali: s);
              }
            }
          }
        }
        if (decoded.containsKey('phrases')) {
          final list = decoded['phrases'] as List<dynamic>;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final h = item['hindi']?.toString();
              final s = item['santhali']?.toString();
              if (h != null && s != null) {
                addEntryDirect(hindi: h, santali: s);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[PhraseDictionary] JSON load error: $e');
    }
  }

  /// Loads every .tsv file in [folderPath] (for native storage scanning)
  Future<void> loadFolder(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return;

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.tsv'));

    for (final file in files) {
      await _loadFile(file);
    }
  }

  Future<void> _loadFile(File file) async {
    try {
      final content = await file.readAsString();
      loadTsvContent(content);
    } catch (_) {}
  }
}

// ---------------------------------------------------------------------
// Tier 2: Fuzzy Match (Levenshtein distance)
// ---------------------------------------------------------------------

class FuzzyMatcher {
  static int levenshtein(String a, String b) {
    final la = a.length, lb = b.length;
    final dp = List.generate(la + 1, (_) => List<int>.filled(lb + 1, 0));
    for (var i = 0; i <= la; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= lb; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= la; i++) {
      for (var j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((v, e) => v < e ? v : e);
      }
    }
    return dp[la][lb];
  }

  static PhraseEntry? findClosest(
    String normalizedInput,
    Map<String, PhraseEntry> exactSentenceMap, {
    double maxDistanceRatio = 0.25,
    double minTokenOverlapRatio = 0.50,
  }) {
    if (normalizedInput.isEmpty || exactSentenceMap.isEmpty) return null;

    final inputTokens = Normalizer.tokenize(normalizedInput).toSet();
    if (inputTokens.isEmpty) return null;

    PhraseEntry? best;
    double bestScore = 0.0;

    for (final entry in exactSentenceMap.entries) {
      final key = entry.key;
      final phraseEntry = entry.value;

      final keyTokens = Normalizer.tokenize(key).toSet();
      if (keyTokens.isEmpty) continue;

      // 1. Token overlap Jaccard-style ratio
      final intersectionCount = inputTokens.intersection(keyTokens).length;
      final maxTokens = inputTokens.length > keyTokens.length ? inputTokens.length : keyTokens.length;
      final tokenOverlapRatio = intersectionCount / maxTokens;

      // 2. Levenshtein ratio
      double levRatio = 0.0;
      if ((key.length - normalizedInput.length).abs() <= key.length * 0.45) {
        final dist = levenshtein(normalizedInput, key);
        final maxLen = normalizedInput.length > key.length ? normalizedInput.length : key.length;
        levRatio = 1.0 - (dist / maxLen.clamp(1, 1 << 30));
      }

      final effectiveTokenRatio = tokenOverlapRatio >= minTokenOverlapRatio ? tokenOverlapRatio : 0.0;
      final effectiveLevRatio = levRatio >= (1.0 - maxDistanceRatio) ? levRatio : 0.0;

      double combinedScore = (effectiveTokenRatio > effectiveLevRatio) ? effectiveTokenRatio : effectiveLevRatio;

      // Give extra bonus to verified (demo mock data) entries to take precedence
      if (combinedScore > 0 && phraseEntry.verified) {
        combinedScore += 0.05;
      }

      if (combinedScore > bestScore) {
        bestScore = combinedScore;
        best = phraseEntry;
      }
    }

    return bestScore >= 0.45 ? best : null;
  }
}

// ---------------------------------------------------------------------
// Tier 3: A* Segmentation Search & Grammatical Santhali Sentence Maker
// ---------------------------------------------------------------------

class _SearchNode implements Comparable<_SearchNode> {
  final int position;
  final double gCost;
  final double fCost;
  final _SearchNode? parent;
  final String? santaliUsed;
  final bool wasUnmatched;

  _SearchNode({
    required this.position,
    required this.gCost,
    required this.fCost,
    this.parent,
    this.santaliUsed,
    this.wasUnmatched = false,
  });

  @override
  int compareTo(_SearchNode other) => fCost.compareTo(other.fCost);
}

class TranslationResult {
  final String santaliText;
  final String method; // "exact" | "fuzzy" | "composed"
  final List<String> unmatchedHindiWords;
  final double latencyMs;

  TranslationResult(this.santaliText, this.method, this.unmatchedHindiWords, {this.latencyMs = 0.0});
}

class AStarSegmenter {
  final PhraseDictionary dict;
  static const double _unmatchedWordPenalty = 3.0;

  AStarSegmenter(this.dict);

  double _phraseCost(PhraseEntry entry, int wordSpan) {
    double cost = 1.0;
    cost -= (wordSpan.clamp(1, 10) - 1) * 0.15;
    if (entry.verified) cost -= 0.1;
    return cost.clamp(0.05, 1.0);
  }

  TranslationResult segment(List<String> tokens, {double startMs = 0.0}) {
    final n = tokens.length;
    if (n == 0) return TranslationResult('', 'composed', [], latencyMs: 0.0);

    final openSet = SimplePriorityQueue<_SearchNode>();
    final bestGCost = List<double>.filled(n + 1, double.infinity);

    final startNode = _SearchNode(position: 0, gCost: 0, fCost: _heuristic(0, n));
    openSet.add(startNode);
    bestGCost[0] = 0;

    _SearchNode? goal;

    while (openSet.isNotEmpty) {
      final current = openSet.removeFirst();
      if (current.position == n) {
        goal = current;
        break;
      }
      if (current.gCost > bestGCost[current.position]) continue;

      final maxLen = (n - current.position).clamp(0, dict.maxPhraseLenWords);
      bool anyPhraseEdge = false;

      for (var len = maxLen; len >= 1; len--) {
        final span = tokens.sublist(current.position, current.position + len).join(' ');
        final entry = dict.phraseMap[span];
        if (entry == null) continue;
        anyPhraseEdge = true;

        final nextPos = current.position + len;
        final newG = current.gCost + _phraseCost(entry, len);
        if (newG < bestGCost[nextPos]) {
          bestGCost[nextPos] = newG;
          openSet.add(_SearchNode(
            position: nextPos,
            gCost: newG,
            fCost: newG + _heuristic(nextPos, n),
            parent: current,
            santaliUsed: entry.santali,
          ));
        }
      }

      if (!anyPhraseEdge || true) {
        final nextPos = current.position + 1;
        final newG = current.gCost + _unmatchedWordPenalty;
        if (newG < bestGCost[nextPos]) {
          bestGCost[nextPos] = newG;
          openSet.add(_SearchNode(
            position: nextPos,
            gCost: newG,
            fCost: newG + _heuristic(nextPos, n),
            parent: current,
            santaliUsed: null,
            wasUnmatched: true,
          ));
        }
      }
    }

    if (goal == null) {
      return TranslationResult(tokens.join(' '), 'composed', tokens, latencyMs: 0.0);
    }

    final parts = <String>[];
    final unmatched = <String>[];
    _SearchNode? node = goal;
    final chain = <_SearchNode>[];
    while (node != null && node.parent != null) {
      chain.add(node);
      node = node.parent;
    }

    for (final step in chain.reversed) {
      if (step.wasUnmatched) {
        final word = tokens[step.position - 1];
        unmatched.add(word);
        // Clean word without square brackets!
        parts.add(word);
      } else {
        parts.add(step.santaliUsed!);
      }
    }

    final rawComposedText = parts.join(' ');
    final grammaticallyRefinedText = _applySanthaliGrammarRules(rawComposedText, tokens);

    return TranslationResult(grammaticallyRefinedText, 'composed', unmatched);
  }

  /// Refines segmented words using Santhali Grammatical Rules (Adverbs, Postpositions, Imperatives, Agreement, Negation)
  String _applySanthaliGrammarRules(String text, List<String> originalTokens) {
    if (text.trim().isEmpty) return text;

    String clean = text;

    // 1. Plural Subject & Imperative Agreement for commands with "सब", "सभी", "बच्चों", "आप", "वे"
    final isPluralSubject = originalTokens.any((t) =>
        t == 'सब' || t == 'सभी' || t == 'बच्चों' || t == 'बच्चे' || t == 'आप' || t == 'वे');

    if (isPluralSubject) {
      // Replace singular imperative verb suffix "ᱢᱮ" (Me) with plural "ᱯᱮ" (Pe)
      clean = clean.replaceAll(RegExp(r'(\b\w+|\S+)\s+ᱢᱮ\b'), r'$1 ᱯᱮ');
    }

    // 2. Prohibition & Negation Patterns ("मत" -> "ᱟᱞᱳ")
    final hasProhibition = originalTokens.any((t) => t == 'मत' || t == 'ना');
    if (hasProhibition) {
      clean = clean.replaceAll(' मत ', ' ᱟᱞᱳ ');
      if (isPluralSubject) {
        clean = clean.replaceAll('ᱟᱞᱳ ᱢᱮ', 'ᱟᱞᱳᱯᱮ').replaceAll('ᱟᱞᱳ ', 'ᱟᱞᱳᱯᱮ ');
      } else {
        clean = clean.replaceAll('ᱟᱞᱳ ᱢᱮ', 'ᱟᱞᱳᱢ').replaceAll('ᱟᱞᱳ ', 'ᱟᱞᱳᱢ ');
      }
    }

    // 3. Postposition Case Transformations & Bonding
    clean = clean
        .replaceAll(' में ', ' ᱨᱮ ')
        .replaceAll(' पर ', ' ᱨᱮ ')
        .replaceAll(' से ', ' ᱠᱷᱚᱱ ')
        .replaceAll(' को ', ' ᱴᱷᱮᱱ ')
        .replaceAll(' के लिए ', ' ᱞᱟᱹᱜᱤᱫ ')
        .replaceAll(' तक ', ' ᱫᱷᱟᱹᱵᱤᱡ ')
        .replaceAll(' साथ ', ' ᱥᱟᱶᱛᱮ ')
        .replaceAll(' के साथ ', ' ᱥᱟᱶᱛᱮ ');

    // 4. Conjunction & Adverb Transformations
    clean = clean
        .replaceAll(' और ', ' ᱟᱨ ')
        .replaceAll(' तथा ', ' ᱟᱨ ')
        .replaceAll(' लेकिन ', ' ᱢᱮᱱᱠᱷᱟᱱ ')
        .replaceAll(' क्योंकि ', ' ᱪᱮᱫᱟᱜ ᱥᱮ ')
        .replaceAll(' इसलिए ', ' ᱚᱱᱟ ᱛᱮ ')
        .replaceAll(' बहुत ', ' ᱟᱹᱰᱤ ')
        .replaceAll(' जल्दी ', ' ᱩᱥᱟᱹᱨᱟ ')
        .replaceAll(' धीरे ', ' ᱵᱟᱹᱭ ᱵᱟᱹᱭ ᱛᱮ ')
        .replaceAll(' हर दिन ', ' ᱫᱤᱱᱟᱹᱢ ᱦᱤᱞᱚᱜ ')
        .replaceAll(' हर रोज ', ' ᱫᱤᱱᱟᱹᱢ ᱦᱤᱞᱚᱜ ')
        .replaceAll(' रोज ', ' ᱫᱤᱱᱟᱹᱢ ᱦᱤᱞᱚᱜ ')
        .replaceAll(' थोड़ी देर ', ' ᱠᱟᱹᱴᱤᱡ ᱜᱷᱟᱹᱲᱤᱡ ');

    return clean.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  double _heuristic(int position, int n) {
    final remaining = n - position;
    if (remaining <= 0) return 0;
    return remaining * 0.1 / 5;
  }
}

// PriorityQueue
class SimplePriorityQueue<T extends Comparable<T>> {
  final List<T> _heap = [];

  bool get isNotEmpty => _heap.isNotEmpty;

  void add(T item) {
    _heap.add(item);
    _heap.sort();
  }

  T removeFirst() => _heap.removeAt(0);
}

// ---------------------------------------------------------------------
// Main Hindi -> Santali Translator Public API
// ---------------------------------------------------------------------

class HindiSantaliTranslator {
  final PhraseDictionary dict;
  late final AStarSegmenter _segmenter;

  HindiSantaliTranslator(this.dict) {
    _segmenter = AStarSegmenter(dict);
  }

  /// Cleans all parenthetical annotations (e.g. "(मिद)", "(इतुन असड़ा)", "(पुथि)") from translated text.
  /// Untranslated words (e.g. "टीचर", "स्टूडेंट", "बर्थडे", "structure") remain plain text without brackets.
  static String cleanSanthaliOutput(String text) {
    if (text.isEmpty) return text;
    String clean = text;
    // Remove parenthetical expressions like "(मिद)" or "(इतुन असड़ा)"
    clean = clean.replaceAll(RegExp(r'\([^)]*\)'), '');
    // Remove square brackets if any
    clean = clean.replaceAll(RegExp(r'\[[^\]]*\]'), '');
    // Replace multiple spaces with a single space
    return clean.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Tier 1 (Exact) -> Tier 2 (Fuzzy) -> Tier 3 (A* Composed with Santhali Grammar Engine)
  TranslationResult translate(String hindiText) {
    final stopwatch = Stopwatch()..start();
    final normalized = Normalizer.normalize(hindiText);
    if (normalized.isEmpty) {
      stopwatch.stop();
      return TranslationResult('', 'exact', [], latencyMs: stopwatch.elapsedMicroseconds / 1000.0);
    }

    // Tier 1: Exact Hash Match
    final exact = dict.exactSentenceMap[normalized];
    if (exact != null) {
      stopwatch.stop();
      return TranslationResult(
        cleanSanthaliOutput(exact.santali),
        'exact',
        [],
        latencyMs: stopwatch.elapsedMicroseconds / 1000.0,
      );
    }

    // Tier 2: Fuzzy Match
    final fuzzy = FuzzyMatcher.findClosest(normalized, dict.exactSentenceMap);
    if (fuzzy != null) {
      stopwatch.stop();
      return TranslationResult(
        cleanSanthaliOutput(fuzzy.santali),
        'fuzzy',
        [],
        latencyMs: stopwatch.elapsedMicroseconds / 1000.0,
      );
    }

    // Tier 3: A* Graph Segmentation with Santhali Grammar Engine
    final tokens = Normalizer.tokenize(normalized);
    final result = _segmenter.segment(tokens);
    stopwatch.stop();

    return TranslationResult(
      cleanSanthaliOutput(result.santaliText),
      result.method,
      result.unmatchedHindiWords,
      latencyMs: stopwatch.elapsedMicroseconds / 1000.0,
    );
  }

  /// Reverse Translation: Santali (Ol Chiki or Devanagari) -> Hindi
  TranslationResult translateReverse(String santaliText) {
    final stopwatch = Stopwatch()..start();
    final normalized = Normalizer.normalize(santaliText);
    if (normalized.isEmpty) {
      stopwatch.stop();
      return TranslationResult('', 'exact', [], latencyMs: stopwatch.elapsedMicroseconds / 1000.0);
    }

    final devanagariSantali = OlChikiTransliteration.toDevanagari(santaliText);
    final devNorm = Normalizer.normalize(devanagariSantali);

    // 1. Exact match in reverse dictionary
    final exactHindi = dict.reverseExactMap[normalized] ??
        dict.reverseExactMap[santaliText.trim()] ??
        dict.reverseExactMap[devNorm] ??
        dict.reverseExactMap[devanagariSantali.trim()];

    if (exactHindi != null) {
      stopwatch.stop();
      return TranslationResult(
        exactHindi,
        'exact',
        [],
        latencyMs: stopwatch.elapsedMicroseconds / 1000.0,
      );
    }

    // 2. Tokenize and replace known Santali words with Hindi equivalents
    final tokens = santaliText.trim().split(RegExp(r'\s+'));
    final translatedTokens = <String>[];
    final unmatched = <String>[];

    for (final token in tokens) {
      final normToken = Normalizer.normalize(token);
      final devToken = Normalizer.normalize(OlChikiTransliteration.toDevanagari(token));

      final mappedHindi = dict.reversePhraseMap[normToken] ??
          dict.reversePhraseMap[token] ??
          dict.reversePhraseMap[devToken];

      if (mappedHindi != null) {
        translatedTokens.add(mappedHindi);
      } else {
        translatedTokens.add(token);
        unmatched.add(token);
      }
    }

    stopwatch.stop();
    final hindiOutput = translatedTokens.join(' ');
    return TranslationResult(
      hindiOutput,
      'composed',
      unmatched,
      latencyMs: stopwatch.elapsedMicroseconds / 1000.0,
    );
  }
}
