import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vernacular_pedagogy/engine/hindi_text_normalizer.dart';

void main() {
  group('HindiTextNormalizer Tests', () {
    test('Splits attached Devanagari particles correctly', () {
      expect(HindiTextNormalizer.normalize('हैपार्क'), 'है पार्क');
      expect(HindiTextNormalizer.normalize('केबादमैं'), 'के बाद मैं');
      expect(HindiTextNormalizer.normalize('मुझेबहुत'), 'मुझे बहुत');
      expect(HindiTextNormalizer.normalize('जातावहां'), 'जाता वहां');
      expect(HindiTextNormalizer.normalize('साथबच्चे'), 'साथ बच्चे');
      expect(HindiTextNormalizer.normalize('हैमेंहर'), 'है में हर');
      expect(HindiTextNormalizer.normalize('सुबहके'), 'सुबह के');
    });

    test('Preserves valid Hindi vocabulary without over-splitting', () {
      expect(HindiTextNormalizer.normalize('कोशिश'), 'कोशिश');
      expect(HindiTextNormalizer.normalize('कारण'), 'कारण');
      expect(HindiTextNormalizer.normalize('सेवा'), 'सेवा');
      expect(HindiTextNormalizer.normalize('नेता'), 'नेता');
      expect(HindiTextNormalizer.normalize('औरत'), 'औरत');
    });

    test('Formats full continuous speech sample accurately', () {
      const sample =
          'Subah ke saat baje hain aur dhoop nikal aayi hai. Main har roz subah jaldi uthta hoon aur ek glass garam paani peeta hoon. Iske baad, main thodi der ke liye park mein ghoomne jaata hoon. Wahan ki taaza hawa mujhe bohot achhi lagti hai. Park se aane ke baad, main apne liye ek cup chai banata hoon aur nasta karta hoon. Yeh samay mera sabse pasandida samay hai kyunki sab kuch bohot shant hota hai.';
      final result = HindiTextNormalizer.normalize(sample);
      debugPrint('NORMALIZED RESULT:\n$result');
      expect(result.contains('.'), true);
      expect(result.contains('Subah ke saat baje hain aur dhoop nikal aayi hai'), true);
    });
  });
}
