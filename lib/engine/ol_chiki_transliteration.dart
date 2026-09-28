/// 100% Comprehensive Ol Chiki (Santali) to Devanagari Phonetic Transliteration Engine
class OlChikiTransliteration {
  static const Map<String, String> _olChikiMap = {
    // Basic Consonants & Vowels (U+1C50 - U+1C6F)
    'ᱚ': 'अ',
    'ᱛ': 'त',
    'ᱜ': 'ग',
    'ᱝ': 'ंग',
    'ᱞ': 'ल',
    'ᱠ': 'क',
    'ᱡ': 'ज',
    'ᱢ': 'म',
    'ᱣ': 'व',
    'ᱤ': 'इ',
    'ᱟ': 'आ', // Ol Chiki AA
    'ᱥ': 'स',
    'ᱦ': 'ह',
    'ᱧ': 'ञ',
    'ᱨ': 'र',
    'ᱩ': 'उ',
    'ᱪ': 'च',
    'ᱫ': 'द',
    'ᱬ': 'ण',
    'ᱭ': 'य',
    'ᱮ': 'ए',
    'ᱯ': 'प',
    'ᱰ': 'ड',
    'ᱱ': 'न',
    'ᱲ': 'ड़',
    'ᱳ': 'ओ',
    'ᱴ': 'ट',
    'ᱵ': 'ब',
    'ᱶ': 'ँ',
    'ᱷ': '',
    'ᱸ': 'ं',
    'ᱹ': '',
    'ᱺ': '',
    'ᱻ': '',
    'ᱼ': '',
    'ᱽ': '', // Ahad / Dega modifier
    // Ol Chiki Digits (U+1C78 - U+1C7F)
    '᱐': '०',
    '᱑': '१',
    '᱒': '२',
    '᱓': '३',
    '᱔': '४',
    '᱕': '५',
    '᱖': '६',
    '᱗': '७',
    '᱘': '८',
    '᱙': '९',
  };

  /// Converts Ol Chiki text to 100% clean Devanagari phonetics for Mobile & Web Speech engines
  static String toDevanagari(String text) {
    if (text.isEmpty) return text;
    final buffer = StringBuffer();
    for (int i = 0; i < text.runes.length; i++) {
      final char = String.fromCharCode(text.runes.elementAt(i));
      buffer.write(_olChikiMap[char] ?? char);
    }

    String result = buffer.toString();

    // Convert independent vowels after consonants to proper Devanagari matras
    const consonants = 'कखगघङचछजझञटठडढणतथदधनपफबभमयरलवशषसहड़ढ़';
    result = result.replaceAllMapped(
      RegExp('([$consonants])([अआइईउऊएऐओऔ])'),
      (match) {
        final c = match.group(1)!;
        final v = match.group(2)!;
        switch (v) {
          case 'अ': return c;
          case 'आ': return '$cा';
          case 'इ': return '$cि';
          case 'ई': return '$cी';
          case 'उ': return '$cु';
          case 'ऊ': return '$cू';
          case 'ए': return '$cे';
          case 'ऐ': return '$cै';
          case 'ओ': return '$cो';
          case 'औ': return '$cौ';
          default: return '$c$v';
        }
      },
    );

    // Strip out any residual raw Ol Chiki unicode characters (Range U+1C50 - U+1C7F)
    result = result.replaceAll(RegExp(r'[\u1C50-\u1C7F]'), '');

    // Clean up multiple spaces
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
