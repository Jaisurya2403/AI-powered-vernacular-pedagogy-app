import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vernacular_pedagogy/translation/translator_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Santhali Morpho-Syntactic Engine & POS Lexicon Tests', () {
    final manager = TranslatorManager();

    setUpAll(() async {
      await manager.initialize();
    });

    test('Loads POS Lexicon & Classroom Idioms into PhraseDictionary', () {
      expect(manager.isInitialized, isTrue);
      expect(manager.translator.dict.exactSentenceMap.isNotEmpty, isTrue);
    });

    test('Translates exact classroom commands accurately', () {
      final res1 = manager.translator.translate('सब बैठ जाओ');
      expect(res1.santaliText, contains('ᱫᱩᱲᱩᱵᱽ ᱯᱮ'));
      expect(res1.latencyMs, lessThan(100.0));

      final res2 = manager.translator.translate('अपनी किताब खोलो');
      expect(res2.santaliText, contains('ᱯᱩᱛᱷᱤ'));
      expect(res2.latencyMs, lessThan(100.0));
    });

    test('Applies Morpho-Syntactic rules for prohibition and plural agreement', () {
      final res1 = manager.translator.translate('चिंता मत करो');
      expect(res1.santaliText, contains('ᱟᱞᱳ'));
      expect(res1.latencyMs, lessThan(100.0));

      final res2 = manager.translator.translate('सब सुनो');
      expect(res2.santaliText, contains('ᱟᱧᱡᱚᱢ ᱯᱮ'));
      expect(res2.latencyMs, lessThan(100.0));
    });

    test('Executes sentence translation in under 500ms (latency check)', () {
      final stopwatch = Stopwatch()..start();
      final res = manager.translator.translate(
        'Main har roz subah jaldi uthta hoon aur ek glass garam paani peeta hoon',
      );
      stopwatch.stop();

      expect(res.santaliText.isNotEmpty, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      debugPrint('[Latency Benchmark] Sentence translated in ${res.latencyMs.toStringAsFixed(2)} ms');
    });
  });
}
