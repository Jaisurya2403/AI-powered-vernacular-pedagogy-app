/// Intelligent Speech Segmenter for Hindi, English, and Vernacular Pedagogy Speech Streams.
/// Handles multi-sentence long paragraphs without dropping sentences or causing partial truncation.
class SpeechSegmenter {
  /// Common Hindi auxiliary verbs and terminal markers that denote sentence boundaries
  static final Set<String> _hindiSentenceEndMarkers = {

    'है',
    'हैं',
    'हो',
    'हूं',
    'हूँ',
    'था',
    'थी',
    'थे',
    'थीं',
    'गया',
    'गए',
    'गई',
    'गयीं',
    'रहा है',
    'रहे हैं',
    'रही है',
    'रहा था',
    'रहे थे',
    'रही थी',
    'सकता है',
    'सकते हैं',
    'सकती है',
    'चाहिए',
    'सीखेंगे',
    'पढ़ेंगे',
    'करेंगे',
    'जाएंगे',
    'आएंगे',
    'लिखेंगे',
    'करो',
    'कीजिए',
    'खोलो',
    'खोलिए',
    'निकालो',
    'निकालिए',
    'पढ़ो',
    'पढ़िए',
    'लिखो',
    'लिखिए',
    'सुनो',
    'सुनिए',
    'बैठो',
    'बैठिए',
    'देखो',
    'देखिए',
    'समझो',
    'समझिए',
    'बताओ',
    'बताइए',
    'दीजिए',
    'लीजिए',
    'लाओ',
    'आइए',
    'जाइए',
  };

  /// Punctuation delimiters

  static final RegExp _punctuationRegex = RegExp(r'[।\.\?!\n;\-]');

  /// Splits a continuous speech paragraph into distinct, coherent sentences
  static List<String> segmentParagraph(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return [];

    final sentences = <String>[];

    // 1. If explicit punctuation exists, split along punctuation
    if (_punctuationRegex.hasMatch(text)) {
      final parts = text.split(RegExp(r'(?<=[।\.\?!\n;\-])\s*'));
      for (final part in parts) {
        final clean = part.trim();
        if (clean.isNotEmpty) {
          sentences.addAll(_segmentByVerbMarkers(clean));
        }
      }
    } else {
      // 2. No punctuation: use natural language verb-terminal & clause boundaries
      sentences.addAll(_segmentByVerbMarkers(text));
    }

    return sentences.where((s) => s.trim().isNotEmpty).toList();
  }

  /// Splits text by Hindi verb markers and clause conjunctions
  static List<String> _segmentByVerbMarkers(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= 4) {
      return [text.trim()];
    }

    final results = <String>[];
    int currentStart = 0;

    for (int i = 0; i < words.length; i++) {
      final word = words[i].replaceAll(RegExp(r'[,।\.\?!]'), '').trim();
      final wordsLeft = words.length - (i + 1);

      // Check for two-word terminal patterns (e.g. "रहा है", "सकते हैं")
      bool isTwoWordMatch = false;
      if (i < words.length - 1) {
        final nextWord = words[i + 1].replaceAll(RegExp(r'[,।\.\?!]'), '').trim();
        final pair = '$word $nextWord';
        if (_hindiSentenceEndMarkers.contains(pair)) {
          isTwoWordMatch = true;
        }
      }

      final isOneWordMatch = _hindiSentenceEndMarkers.contains(word);

      if ((isOneWordMatch || isTwoWordMatch) && (i - currentStart >= 2)) {
        final clauseEnd = isTwoWordMatch ? i + 1 : i;

        if (wordsLeft > 0) {
          final segment = words.sublist(currentStart, clauseEnd + 1).join(' ').trim();
          if (segment.isNotEmpty) {
            results.add(segment);
            currentStart = clauseEnd + 1;
            if (isTwoWordMatch) i++; // skip second word
          }
        }
      }
    }

    // Add remainder
    if (currentStart < words.length) {
      final remainder = words.sublist(currentStart).join(' ').trim();
      if (remainder.isNotEmpty) {
        results.add(remainder);
      }
    }

    return results.isNotEmpty ? results : [text.trim()];
  }


  /// Extracts newly spoken sentences by comparing the incoming speech stream with committed history
  static List<String> extractNewDeltas({
    required String rawRecognizedStream,
    required List<String> committedSentences,
  }) {
    final segments = segmentParagraph(rawRecognizedStream);
    if (segments.isEmpty) return [];

    final newSentences = <String>[];

    for (final segment in segments) {
      final clean = segment.trim();
      if (clean.isEmpty) continue;

      final normalizedKey = _normalizeForComparison(clean);

      // Check if this segment was already committed
      bool alreadyCommitted = false;
      for (final prev in committedSentences) {
        final prevKey = _normalizeForComparison(prev);
        if (prevKey == normalizedKey || prevKey.endsWith(normalizedKey) || normalizedKey.endsWith(prevKey)) {
          alreadyCommitted = true;
          break;
        }
      }

      if (!alreadyCommitted) {
        newSentences.add(clean);
      }
    }

    return newSentences;
  }

  static String _normalizeForComparison(String s) {
    return s.replaceAll(RegExp(r'[\s\.\।\?!\n,;\-]'), '').toLowerCase();
  }
}
