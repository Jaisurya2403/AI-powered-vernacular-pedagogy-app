import 'package:flutter_test/flutter_test.dart';
import 'package:vernacular_pedagogy/translation/hindi_santali_translator.dart';
import 'package:vernacular_pedagogy/engine/ol_chiki_transliteration.dart';

void main() {
  group('Bidirectional Santali ↔ Hindi Translation Tests', () {
    late PhraseDictionary dictionary;
    late HindiSantaliTranslator translator;

    setUpAll(() {
      dictionary = PhraseDictionary();
      dictionary.addEntryDirect(hindi: 'नमस्ते', santali: 'ᱡᱚᱦᱟᱨ');
      dictionary.addEntryDirect(hindi: 'सब बैठ जाओ', santali: 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱫᱩᱲᱩᱵᱽ ᱯᱮ');
      dictionary.addEntryDirect(hindi: 'ध्यान से सुनो', santali: 'ᱢᱚᱱ ᱮᱢ ᱠᱟᱛᱮ ᱟᱧㄐᱚᱢ ᱢᱮ');
      translator = HindiSantaliTranslator(dictionary);
    });

    test('Translates Forward: Hindi ➔ Santali (Ol Chiki)', () {
      final res = translator.translate('नमस्ते');
      expect(res.santaliText, 'ᱡᱚᱦᱟᱨ');
      expect(res.method, 'exact');
    });

    test('Translates Reverse: Santali Ol Chiki ➔ Hindi', () {
      final res = translator.translateReverse('ᱡᱚᱦᱟᱨ');
      expect(res.santaliText, 'नमस्ते');
      expect(res.method, 'exact');
    });

    test('Translates Reverse: Santali Devanagari Phonetics ➔ Hindi', () {
      final res = translator.translateReverse('जहार');
      expect(res.santaliText, 'नमस्ते');
      expect(res.method, 'exact');
    });

    test('OlChikiTransliteration converts Ol Chiki to Devanagari phonetics', () {
      final dev = OlChikiTransliteration.toDevanagari('ᱡᱚᱦᱟᱨ');
      expect(dev, 'जहार');
    });
  });
}
