import 'package:flutter_test/flutter_test.dart';
import 'package:vernacular_pedagogy/translation/hindi_santali_translator.dart';
import 'package:vernacular_pedagogy/translation/translator_manager.dart';

void main() {
  group('Meaning-Anchored Semantic Translator Tests', () {
    late TranslatorManager manager;
    late HindiSantaliTranslator translator;

    setUp(() {
      manager = TranslatorManager();
      translator = manager.translator;
    });

    test('Translates "मेरी बात सुनो" accurately to natural Santhali Ol Chiki', () {
      final res = translator.translate('मेरी बात सुनो');
      expect(res.santaliText, 'ᱤᱧᱟᱜ ᱠᱟᱛᱷᱟ ᱟᱧᱡᱚᱢ ᱢᱮ');
    });

    test('Translates "देखो एक बात सुनो" accurately to natural Santhali Ol Chiki', () {
      final res = translator.translate('देखो एक बात सुनो');
      expect(res.santaliText, 'ᱧᱮᱞ ᱢᱮ ᱢᱤᱫᱴᱟᱝ ᱠᱟᱛᱷᱟ ᱟᱧᱡᱚᱢ ᱢᱮ');
    });

    test('Translates "ध्यान से सुनो" accurately to "ᱢᱚᱱ ᱮᱢ ᱠᱟᱛᱮ ᱟᱧᱡᱚᱢ ᱢᱮ"', () {
      final res = translator.translate('ध्यान से सुनो');
      expect(res.santaliText, 'ᱢᱚᱱ ᱮᱢ ᱠᱟᱛᱮ ᱟᱧᱡᱚᱢ ᱢᱮ');
    });

    test('Translates "सब बैठ जाओ" accurately to "ᱡᱚᱛᱚ ᱦᱚᱲ ᱫᱩᱲᱩᱵᱽ ᱯᱮ"', () {
      final res = translator.translate('सब बैठ जाओ');
      expect(res.santaliText, 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱫᱩᱲᱩᱵᱽ ᱯᱮ');
    });

    test('Translates mathematical idiom "दो और दो चार होते हैं" accurately', () {
      final res = translator.translate('दो और दो चार होते हैं');
      expect(res.santaliText.contains('ᱵᱟᱨ'), true);
      expect(res.santaliText.contains('ᱯᱳᱱ'), true);
    });
  });
}
