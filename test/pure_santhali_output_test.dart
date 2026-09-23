import 'package:flutter_test/flutter_test.dart';
import 'package:vernacular_pedagogy/translation/hindi_santali_translator.dart';

void main() {
  group('Pure Santhali Output & Devanagari Parentheses Sanitization Tests', () {
    late PhraseDictionary dict;
    late HindiSantaliTranslator translator;

    setUp(() {
      dict = PhraseDictionary();
      // Add test seed dictionary entries
      dict.addEntryDirect(hindi: 'एक', santali: 'ᱢᱤᱫ');
      dict.addEntryDirect(hindi: 'स्कूल', santali: 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ');
      dict.addEntryDirect(hindi: 'किताब', santali: 'ᱯᱩᱛᱷᱤ');
      dict.addEntryDirect(hindi: 'नमस्ते', santali: 'ᱡᱚᱦᱟᱨ');

      translator = HindiSantaliTranslator(dict);
    });

    test('cleanSanthaliOutput removes parenthetical annotations (मिद), (इतुन असड़ा), (पुथि)', () {
      expect(HindiSantaliTranslator.cleanSanthaliOutput('ᱢᱤᱫ (मिद)'), 'ᱢᱤᱫ');
      expect(HindiSantaliTranslator.cleanSanthaliOutput('ᱤᱛᱩᱱ ᱟᱥᱲᱟ (इतुन असड़ा)'), 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ');
      expect(HindiSantaliTranslator.cleanSanthaliOutput('ᱯᱩᱛᱷᱤ [पुथि]'), 'ᱯᱩᱛᱷᱤ');
    });

    test('Untranslated words remain as clean plain text without brackets', () {
      final res = translator.translate('टीचर स्टूडेंट बर्थडे');
      expect(res.santaliText, 'टीचर स्टूडेंट बर्थडे');
      expect(res.santaliText.contains('('), false);
      expect(res.santaliText.contains(')'), false);
      expect(res.santaliText.contains('['), false);
      expect(res.santaliText.contains(']'), false);
    });

    test('Translation output contains zero parenthetical text', () {
      final res1 = translator.translate('नमस्ते एक किताब');
      expect(res1.santaliText.contains('('), false);
      expect(res1.santaliText.contains(')'), false);
      expect(res1.santaliText, 'ᱡᱚᱦᱟᱨ ᱢᱤᱫ ᱯᱩᱛᱷᱤ');
    });
  });
}
