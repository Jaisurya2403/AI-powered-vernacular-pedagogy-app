import 'package:flutter_test/flutter_test.dart';
import 'package:vernacular_pedagogy/engine/speech_segmenter.dart';

void main() {
  group('SpeechSegmenter Paragraph & Multi-Sentence Tests', () {
    test('Correctly segments a 5-sentence paragraph with punctuation', () {
      const paragraph =
          'नमस्ते बच्चों आप सब कैसे हैं। आज हम गणित सीखेंगे। अपनी किताब निकालिए। पृष्ठ संख्या दस खोलिए। ध्यान से समझिए।';

      final sentences = SpeechSegmenter.segmentParagraph(paragraph);

      expect(sentences.length, 5);
      expect(sentences[0], 'नमस्ते बच्चों आप सब कैसे हैं।');
      expect(sentences[1], 'आज हम गणित सीखेंगे।');
      expect(sentences[2], 'अपनी किताब निकालिए।');
      expect(sentences[3], 'पृष्ठ संख्या दस खोलिए।');
      expect(sentences[4], 'ध्यान से समझिए।');
    });

    test('Correctly segments a 5-sentence continuous speech paragraph WITHOUT punctuation', () {
      const paragraph =
          'नमस्ते बच्चों आप सब कैसे हैं आज हम गणित सीखेंगे सभी बच्चे अपनी किताब निकालिए और पृष्ठ संख्या दस खोलिए ध्यान से समझिए और हल कीजिए';

      final sentences = SpeechSegmenter.segmentParagraph(paragraph);

      // Must capture multiple distinct sentences, not 1 huge chunk or partial lines
      expect(sentences.length >= 4, true);
      expect(sentences.any((s) => s.contains('नमस्ते बच्चों')), true);
      expect(sentences.any((s) => s.contains('गणित सीखेंगे')), true);
      expect(sentences.any((s) => s.contains('किताब निकालिए')), true);
      expect(sentences.any((s) => s.contains('हल कीजिए')), true);
    });

    test('Extracts new delta sentences without dropping or truncating lines', () {
      final committed = [
        'नमस्ते बच्चों आप सब कैसे हैं',
        'आज हम गणित सीखेंगे',
      ];

      const incomingStream =
          'नमस्ते बच्चों आप सब कैसे हैं आज हम गणित सीखेंगे अपनी किताब निकालिए और पृष्ठ संख्या दस खोलिए';

      final newDeltas = SpeechSegmenter.extractNewDeltas(
        rawRecognizedStream: incomingStream,
        committedSentences: committed,
      );

      expect(newDeltas.isNotEmpty, true);
      expect(newDeltas.any((s) => s.contains('किताब निकालिए')), true);
      // Already committed sentences must not be re-emitted
      expect(newDeltas.any((s) => s == 'नमस्ते बच्चों आप सब कैसे हैं'), false);
    });
  });
}
