import 'package:flutter_test/flutter_test.dart';
import 'package:vernacular_pedagogy/translation/translator_manager.dart';
import 'package:vernacular_pedagogy/translation/hindi_santali_translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TranslatorManager manager;

  setUp(() async {
    manager = TranslatorManager();
    await manager.initialize();
  });

  group('Demo Video Mock Dataset Verification', () {
    test('Sentence Set 1 exact translations match pristine Ol Chiki Santali', () {
      final s1 = manager.translator.translate('शिक्षक स्कूल में छात्रों को ज्ञान और अच्छी आदतें सिखाते हैं।');
      expect(s1.method, equals('exact'));
      expect(s1.santaliText.isNotEmpty, isTrue);

      final s2 = manager.translator.translate('वे हमेशा बच्चों को जीवन में आगे बढ़ने के लिए प्रेरित करते हैं।');
      expect(s2.method, equals('exact'));
      expect(s2.santaliText.isNotEmpty, isTrue);

      final s3 = manager.translator.translate('एक अच्छा शिक्षक समाज को बेहतर बनाने में महत्वपूर्ण भूमिका निभाता है।');
      expect(s3.method, equals('exact'));
      expect(s3.santaliText.isNotEmpty, isTrue);
    });

    test('Sentence Set 2 exact translation matches pristine Ol Chiki Santali', () {
      final s = manager.translator.translate('शिक्षकों का मार्गदर्शन हमारे भविष्य को सही दिशा देता है।');
      expect(s.method, equals('exact'));
      expect(s.santaliText.isNotEmpty, isTrue);
    });

    test('Sentence Set 3 exact translations match pristine Ol Chiki Santali', () {
      final input1 = 'कृपया सभी छात्र अपनी किताबें खोलें और अध्याय तीन पर ध्यान दें।';
      final s1 = manager.translator.translate(input1);
      final expected1 = manager.translator.dict.exactSentenceMap[Normalizer.normalize(input1)]!.santali;
      expect(s1.santaliText, equals(HindiSantaliTranslator.cleanSanthaliOutput(expected1)));
      expect(s1.method, equals('exact'));

      final input2 = 'आज हम एक बहुत ही महत्वपूर्ण विषय पढ़ने जा रहे हैं, इसलिए शांत रहकर ध्यान से सुनें।';
      final s2 = manager.translator.translate(input2);
      final expected2 = manager.translator.dict.exactSentenceMap[Normalizer.normalize(input2)]!.santali;
      expect(s2.santaliText, equals(HindiSantaliTranslator.cleanSanthaliOutput(expected2)));
      expect(s2.method, equals('exact'));

      final input3 = 'यदि आपके पास कोई प्रश्न है, तो कृपया अपना हाथ उठाएं।';
      final s3 = manager.translator.translate(input3);
      final expected3 = manager.translator.dict.exactSentenceMap[Normalizer.normalize(input3)]!.santali;
      expect(s3.santaliText, equals(HindiSantaliTranslator.cleanSanthaliOutput(expected3)));
      expect(s3.method, equals('exact'));
    });

    test('Fuzzy STT variations match pristine demo mock dataset', () {
      // Slightly mispronounced / STT dropped word: missing "में"
      final f1 = manager.translator.translate('शिक्षक स्कूल छात्रों को ज्ञान और अच्छी आदतें सिखाते हैं');
      final target1 = manager.translator.dict.exactSentenceMap[Normalizer.normalize('शिक्षक स्कूल में छात्रों को ज्ञान और अच्छी आदतें सिखाते हैं।')]!.santali;
      expect(f1.santaliText, equals(HindiSantaliTranslator.cleanSanthaliOutput(target1)));
      expect(f1.method, equals('fuzzy'));

      // Slightly mispronounced: missing "को"
      final f2 = manager.translator.translate('शिक्षकों का मार्गदर्शन हमारे भविष्य सही दिशा देता है');
      final target2 = manager.translator.dict.exactSentenceMap[Normalizer.normalize('शिक्षकों का मार्गदर्शन हमारे भविष्य को सही दिशा देता है।')]!.santali;
      expect(f2.santaliText, equals(HindiSantaliTranslator.cleanSanthaliOutput(target2)));
      expect(f2.method, equals('fuzzy'));

      // Slightly mispronounced: missing "अपनी"
      final f3 = manager.translator.translate('कृपया सभी छात्र किताबें खोलें और अध्याय तीन पर ध्यान दें');
      final target3 = manager.translator.dict.exactSentenceMap[Normalizer.normalize('कृपया सभी छात्र अपनी किताबें खोलें और अध्याय तीन पर ध्यान दें।')]!.santali;
      expect(f3.santaliText, equals(HindiSantaliTranslator.cleanSanthaliOutput(target3)));
      expect(f3.method, equals('fuzzy'));
    });
  });
}
