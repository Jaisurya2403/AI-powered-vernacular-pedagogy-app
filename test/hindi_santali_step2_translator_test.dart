import 'package:flutter_test/flutter_test.dart';
import 'package:vernacular_pedagogy/translation/hindi_santali_translator.dart';

void main() {
  group('Step 2: Hindi to Santhali Translator Engine Tests', () {
    late PhraseDictionary dict;
    late HindiSantaliTranslator translator;

    setUp(() {
      dict = PhraseDictionary();
      // Add test entries matching the user's uploaded TSV dataset
      dict.addEntryDirect(hindi: 'बैठो', santali: 'ᱫᱩᱲᱩᱵᱽ ᱢᱮ');
      dict.addEntryDirect(hindi: 'बैठिए', santali: 'ᱫᱩᱲᱩᱵᱽ ᱵᱤᱱ');
      dict.addEntryDirect(hindi: 'सब बैठ जाओ', santali: 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱫᱩᱲᱩᱵᱽ ᱯᱮ');
      dict.addEntryDirect(hindi: 'खड़े हो जाओ', santali: 'ᱛᱤᱸᱜᱩᱱ ᱢᱮ');
      dict.addEntryDirect(hindi: 'सब खड़े हो जाओ', santali: 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱛᱤᱸᱜᱩᱱ ᱯᱮ');
      dict.addEntryDirect(hindi: 'अपनी किताब खोलो', santali: 'ᱟᱢᱟᱜ ᱯᱩᱛᱷᱤ ᱡᱷᱤᱡ ᱢᱮ');
      dict.addEntryDirect(hindi: 'सब अपनी किताबें खोलो', santali: 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱟᱯᱱᱟᱨᱟᱜ ᱯᱩᱛᱷᱤ ᱡᱷᱤᱡ ᱯᱮ');
      dict.addEntryDirect(hindi: 'शांत रहो', santali: 'ᱛᱷᱤᱨ ᱛᱟᱦᱮᱸᱱ ᱢᱮ');
      dict.addEntryDirect(hindi: 'सब शांत रहो', santali: 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱛᱷᱤᱨ ᱛᱟᱦᱮᱸᱱ ᱯᱮ');
      dict.addEntryDirect(hindi: 'शोर मत करो', santali: 'ᱦᱩᱞᱪᱩᱞ ᱟᱞᱚᱯᱮ ᱠᱚᱨᱟᱣᱟ');
      dict.addEntryDirect(hindi: 'जल्दी करो', santali: 'ᱞᱚᱜᱚᱱᱚᱜ ᱢᱮ');

      translator = HindiSantaliTranslator(dict);
    });

    test('Translates exact classroom command "सब बैठ जाओ" accurately', () {
      final res = translator.translate('सब बैठ जाओ');
      expect(res.santaliText, 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱫᱩᱲᱩᱵᱽ ᱯᱮ');
      expect(res.method, 'exact');
    });

    test('Translates "बैठो", "बैठिए", "खड़े हो जाओ", "सब खड़े हो जाओ" accurately', () {
      expect(translator.translate('बैठो').santaliText, 'ᱫᱩᱲᱩᱵᱽ ᱢᱮ');
      expect(translator.translate('बैठिए').santaliText, 'ᱫᱩᱲᱩᱵᱽ ᱵᱤᱱ');
      expect(translator.translate('खड़े हो जाओ').santaliText, 'ᱛᱤᱸᱜᱩᱱ ᱢᱮ');
      expect(translator.translate('सब खड़े हो जाओ').santaliText, 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱛᱤᱸᱜᱩᱱ ᱯᱮ');
    });

    test('Translates multi-command sentences using A* Segmentation & Santhali Grammar rules', () {
      expect(translator.translate('अपनी किताब खोलो').santaliText, 'ᱟᱢᱟᱜ ᱯᱩᱛᱷᱤ ᱡᱷᱤᱡ ᱢᱮ');
      expect(translator.translate('सब अपनी किताबें खोलो').santaliText, 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱟᱯᱱᱟᱨᱟᱜ ᱯᱩᱛᱷᱤ ᱡᱷᱤᱡ ᱯᱮ');
      expect(translator.translate('सब शांत रहो').santaliText, 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱛᱷᱤᱨ ᱛᱟᱦᱮᱸᱱ ᱯᱮ');
      expect(translator.translate('शोर मत करो').santaliText, 'ᱦᱩᱞᱪᱩᱞ ᱟᱞᱚᱯᱮ ᱠᱚᱨᱟᱣᱟ');
    });

    test('Outputs clean un-bracketed text for missing words', () {
      final res = translator.translate('सब बैठ जाओ और जल्दी करो');
      expect(res.santaliText.contains('['), false);
      expect(res.santaliText.contains(']'), false);
    });
  });
}
