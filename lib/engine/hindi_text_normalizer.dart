/// Utility class for cleaning, normalizing, and fixing attached/glued Hindi & Devanagari text
class HindiTextNormalizer {
  HindiTextNormalizer._();

  /// Fixes glued/concatenated Devanagari and Hinglish words, normalizes spaces & punctuation.
  static String normalize(String text) {
    if (text.trim().isEmpty) return text;

    String clean = text;

    // 1. Split after auxiliary verbs or multi-syllable postpositions followed immediately by a new Devanagari word root
    // Longest alternatives first: हैं before है
    final splitAfterKeywords = RegExp(
      r'(हैं|है|हूं|हुं|था|थी|थे|जाता|जाती|जाते|गया|गयी|गए|हुआ|हुई|हुए|बजे|चाहिए|लगा|लगी|लगे|साथ|बाद)(?=[\u0905-\u0939])',
    );
    clean = clean.replaceAllMapped(splitAfterKeywords, (m) => '${m.group(1)} ');

    // 2. Split before postpositions, pronouns, or keywords ONLY when preceded by any Devanagari character (\u0900-\u097F)
    // Leaves standalone words like "कोशिश", "कारण", "सेवा", "नेता" untouched!
    final splitBeforeKeywords = RegExp(
      r'(?<=[\u0900-\u097F])(के|का|की|को|में|से|पर|तक|ने|बाद|साथ|लिए|अनुसार|द्वारा|सामने|पीछे|मैं|मुझे|मेरा|मेरी|मेरे|तुम|वह|यह|वे|वहां|यहां|हर|सब|बहुत|सबसे|पार्क|सुबह|शाम|रात|एक|दो|तीन|चार|पांच|छह|सात|आठ|नौ|दस|ताजा|हवा|चाय|नाश्ता|नस्ता|समय|शांत|पानी|गरम|रोज|उत्थता|उठता|पीता|घूमने)',
    );
    clean = clean.replaceAllMapped(splitBeforeKeywords, (m) => ' ${m.group(1)}');

    // 3. Handle Hinglish / Transliterated glued words (Roman script Hindi)
    // Only split Roman postpositions/auxiliaries when attached to known Hinglish word roots (prevents splitting "park", "karta", "hain")
    final hinglishPrefixRegex = RegExp(
      r'\b(hain|hai|hoon|tha|thi|the|ke|ka|ki|ko|mein|se|par|tak|ne|aur|baad|saath|jaata|jaati|jaate)(?=(main|mujhe|mera|meri|mere|tum|wah|yeh|ve|wahan|yahan|har|sab|bohot|bahut|park|subah|shaam|raat|baad))',
      caseSensitive: false,
    );
    clean = clean.replaceAllMapped(hinglishPrefixRegex, (m) => '${m.group(1)} ');

    final hinglishSuffixRegex = RegExp(
      r'(?<=(main|mujhe|mera|meri|mere|tum|wah|yeh|ve|wahan|yahan|har|sab|bohot|bahut|park|subah|shaam|raat))(hai|hain|hoon|tha|thi|the|ke|ka|ki|ko|mein|se|par|tak|ne|aur|baad|saath)\b',
      caseSensitive: false,
    );
    clean = clean.replaceAllMapped(hinglishSuffixRegex, (m) => ' ${m.group(2)}');

    // 4. Ensure proper spaces around Hindi full stop (।), standard period, comma, question & exclamation marks
    clean = clean
        .replaceAll('।', ' । ')
        .replaceAll('.', ' . ')
        .replaceAll('?', ' ? ')
        .replaceAll('!', ' ! ')
        .replaceAll(',', ' , ');

    // 5. Collapse duplicate spaces and trim
    clean = clean.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

    return clean;
  }
}
