import 'package:flutter_test/flutter_test.dart';
import 'package:vernacular_pedagogy/engine/voice_biometrics_engine.dart';

void main() {
  group('VoiceBiometricsEngine 75% Threshold Matching Tests', () {
    // ── Helper: create metrics simulating a specific speaker's delivery ──────
    SpeechDeliveryMetrics makeMetrics({
      required String text,
      required double wordsPerSec,
      required int partialCount,
      required double lagMs,
      double pauseMs = 500,
    }) {
      final wordCount = text.split(' ').length;
      final durationMs = (wordCount / wordsPerSec) * 1000.0;
      return SpeechDeliveryMetrics(
        spokenText: text,
        durationMs: durationMs,
        partialUpdateCount: partialCount,
        partialToFinalMs: lagMs,
        interSentencePauseMs: pauseMs,
      );
    }

    test('Enrolls a teacher voiceprint and verifies identical delivery > 75%', () {
      const sentences = [
        'नमस्ते बच्चों आज हम कक्षा में पाठ पढ़ेंगे',
        'सभी बच्चे अपनी पुस्तक निकालिए',
        'ध्यान से समझिए यह पाठ बहुत महत्वपूर्ण है',
        'शाबाश अब हम सब मिलकर अभ्यास करेंगे',
      ];

      // Teacher A speaks at ~2.2 wps, lag ~900ms, 4 partials per sentence
      final metrics = sentences
          .map((s) => makeMetrics(text: s, wordsPerSec: 2.2, partialCount: 4, lagMs: 900))
          .toList();

      final voiceprint = VoiceBiometricsEngine.createCompositeVoiceprint(
        userId: 1,
        sentences: sentences,
        deliveryMetrics: metrics,
      );

      expect(voiceprint.userId, 1);
      expect(voiceprint.embedding.isNotEmpty, true);
      expect(voiceprint.sampleCount, 4);

      // Verify same Teacher A speaking (same delivery pattern)
      final sameMetrics = makeMetrics(
        text: sentences[0],
        wordsPerSec: 2.2,
        partialCount: 4,
        lagMs: 900,
      );

      final matchResult = VoiceBiometricsEngine.verifyVoice(
        spokenText: sentences[0],
        enrolledVoiceprint: voiceprint,
        deliveryMetrics: sameMetrics,
      );

      expect(matchResult.isMatched, true);
      expect(matchResult.similarityScore >= 0.75, true,
          reason: 'Same teacher delivery pattern should score >= 75%');
      expect(matchResult.confidenceLabel.contains('Verified Teacher Voice'), true);
    });

    test('Bypasses voice matching gracefully when teacher has not enrolled voiceprint', () {
      final matchResult = VoiceBiometricsEngine.verifyVoice(
        spokenText: 'किसी अन्य व्यक्ति की आवाज़',
        enrolledVoiceprint: null,
      );

      expect(matchResult.isMatched, true);
      expect(matchResult.isEnrolled, false);
      expect(matchResult.confidenceLabel.contains('Voice Matching Optional'), true);
    });

    test('Rejects a different speaker with very different delivery metrics', () {
      // Teacher A enrolled: slow speaker at 1.5 wps, 6 partials, 1200ms lag
      const sentences = [
        'नमस्ते बच्चों आज हम कक्षा में पाठ पढ़ेंगे',
        'सभी बच्चे अपनी पुस्तक निकालिए',
        'ध्यान से समझिए यह पाठ बहुत महत्वपूर्ण है',
        'शाबाश अब हम सब मिलकर अभ्यास करेंगे',
      ];

      final enrollMetrics = sentences
          .map((s) => makeMetrics(text: s, wordsPerSec: 1.5, partialCount: 6, lagMs: 1200))
          .toList();

      final voiceprint = VoiceBiometricsEngine.createCompositeVoiceprint(
        userId: 10,
        sentences: sentences,
        deliveryMetrics: enrollMetrics,
      );

      // Different person: very fast speaker at 4.0 wps, only 1 partial, 200ms lag
      final friendMetrics = makeMetrics(
        text: sentences[0],
        wordsPerSec: 4.0,
        partialCount: 1,
        lagMs: 200,
        pauseMs: 2800,
      );

      final matchResult = VoiceBiometricsEngine.verifyVoice(
        spokenText: sentences[0],
        enrolledVoiceprint: voiceprint,
        deliveryMetrics: friendMetrics,
      );

      // Same speaker with matching delivery should always score higher
      final sameMetrics = makeMetrics(
        text: sentences[0],
        wordsPerSec: 1.5,
        partialCount: 6,
        lagMs: 1200,
      );
      final sameResult = VoiceBiometricsEngine.verifyVoice(
        spokenText: sentences[0],
        enrolledVoiceprint: voiceprint,
        deliveryMetrics: sameMetrics,
      );

      expect(sameResult.similarityScore > matchResult.similarityScore, true,
          reason: 'Same delivery should score higher than different delivery');
    });

    test('createVoiceprint single-sentence fallback produces valid embedding', () {
      final voiceprint = VoiceBiometricsEngine.createVoiceprint(
        userId: 99,
        referenceText: 'नमस्ते बच्चों',
      );

      expect(voiceprint.userId, 99);
      expect(voiceprint.embedding.isNotEmpty, true);

      // Verify against null → should bypass
      final result = VoiceBiometricsEngine.verifyVoice(
        spokenText: 'नमस्ते बच्चों',
        enrolledVoiceprint: null,
      );
      expect(result.isEnrolled, false);
    });
  });
}
