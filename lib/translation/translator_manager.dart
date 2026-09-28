import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'hindi_santali_translator.dart';

class TranslatorManager {
  static final TranslatorManager _instance = TranslatorManager._internal();
  factory TranslatorManager() => _instance;

  final PhraseDictionary _sharedDictionary = PhraseDictionary();
  late final HindiSantaliTranslator _translator;
  bool _isInitialized = false;

  TranslatorManager._internal() {
    _seedDefaultDictionary(_sharedDictionary);
    _translator = HindiSantaliTranslator(_sharedDictionary);
  }

  HindiSantaliTranslator get translator => _translator;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Asset paths for all TSV & JSON datasets (including new meaning-anchored corpus)
    final assetPaths = [
      'assets/datasets/hindi_santali/santhali_grammar_pos_lexicon.json',
      'assets/datasets/hindi_santali/meaning_anchored_corpus.json',
      'assets/datasets/hindi_santali/hindi_santali_school_dataset_simple.tsv',
      'assets/datasets/hindi_santali/school_words_hindi_santali_300.tsv',
      'assets/datasets/hindi_santali/classroom_phrases.tsv',
      'assets/datasets/hindi_santali/nipun_fln_corpus.tsv',
      'assets/datasets/hindi_santhali_dataset.json',
      'assets/phrase_bank/classroom_phrases.json',
    ];

    for (final path in assetPaths) {
      try {
        final content = await rootBundle.loadString(path);
        if (path.endsWith('.tsv')) {
          _sharedDictionary.loadTsvContent(content);
        } else if (path.endsWith('.json')) {
          _sharedDictionary.loadJsonContent(content);
        }
        debugPrint('[TranslatorManager] Successfully loaded dataset asset: $path');
      } catch (e) {
        debugPrint('[TranslatorManager] Failed to load dataset asset $path: $e');
      }
    }

    if (!kIsWeb) {
      try {
        final appDir = await getApplicationSupportDirectory();
        final targetDir = Directory('${appDir.path}/hindi_santali');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        for (final assetPath in assetPaths.where((p) => p.endsWith('.tsv'))) {
          try {
            final fileName = assetPath.split('/').last;
            final file = File('${targetDir.path}/$fileName');
            final content = await rootBundle.loadString(assetPath);
            await file.writeAsString(content);
          } catch (_) {}
        }

        await _sharedDictionary.loadFolder(targetDir.path);
      } catch (e) {
        debugPrint('[TranslatorManager] Native folder load info: $e');
      }
    }

    _isInitialized = true;
    debugPrint('[TranslatorManager] Loaded ${_sharedDictionary.exactSentenceMap.length} exact sentences & phrases into 3-Tier Translator!');
  }

  void _seedDefaultDictionary(PhraseDictionary dict) {
    // ── DEMO MOCK DATASET 1: Paragraph 1 Sentences & Full Paragraph ─────────
    dict.addEntryDirect(
      hindi: 'शिक्षक स्कूल में छात्रों को ज्ञान और अच्छी आदतें सिखाते हैं।',
      santali: 'ᱥᱤᱠᱷᱱᱟ ᱜᱩᱨᱩ ᱥᱠᱩᱞ ᱨᱮ ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱠᱚ ᱧᱟᱱ ᱟᱨ ᱵᱷᱟᱞᱚ ᱥᱟᱹᱦᱟᱡ ᱥᱤᱠᱷᱟᱣ ᱠᱚᱣᱟ।',
      verified: true,
    );
    dict.addEntryDirect(
      hindi: 'वे हमेशा बच्चों को जीवन में आगे बढ़ने के लिए प्रेरित करते हैं।',
      santali: 'ᱩᱱᱠᱩ ᱡᱤᱣᱤ ᱨᱮ ᱞᱟᱦᱟᱣ ᱞᱟᱹᱜᱤᱫ ᱦᱟᱢᱟᱹᱞ ᱠᱚ ᱦᱟᱹᱣᱠᱟᱹᱣ ᱢᱮᱱᱟᱜ ᱠᱟᱱᱟ।',
      verified: true,
    );
    dict.addEntryDirect(
      hindi: 'एक अच्छा शिक्षक समाज को बेहतर बनाने में महत्वपूर्ण भूमिका निभाता है।',
      santali: 'ᱢᱤᱫ ᱵᱷᱟᱞᱚ ᱜᱩᱨᱩ ᱥᱚᱢᱟᱡ ᱵᱷᱟᱞᱚ ᱵᱟᱱᱟᱣ ᱨᱮ ᱢᱟᱨᱟᱝ ᱵᱷᱩᱢᱤᱠᱟ ᱮᱢᱟᱭᱟ।',
      verified: true,
    );
    dict.addEntryDirect(
      hindi: 'शिक्षक स्कूल में छात्रों को ज्ञान और अच्छी आदतें सिखाते हैं। वे हमेशा बच्चों को जीवन में आगे बढ़ने के लिए प्रेरित करते हैं। एक अच्छा शिक्षक समाज को बेहतर बनाने में महत्वपूर्ण भूमिका निभाता है।',
      santali: 'ᱥᱤᱠᱷᱱᱟ ᱜᱩᱨᱩ ᱥᱠᱩᱞ ᱨᱮ ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱠᱚ ᱧᱟᱱ ᱟᱨ ᱵᱷᱟᱞᱚ ᱥᱟᱹᱦᱟᱡ ᱥᱤᱠᱷᱟᱣ ᱠᱚᱣᱟ। ᱩᱱᱠᱩ ᱡᱤᱣᱤ ᱨᱮ ᱞᱟᱦᱟᱣ ᱞᱟᱹᱜᱤᱫ ᱦᱟᱢᱟᱹᱞ ᱠᱚ ᱦᱟᱹᱣᱠᱟᱹᱣ ᱢᱮᱱᱟᱜ ᱠᱟᱱᱟ। ᱢᱤᱫ ᱵᱷᱟᱞᱚ ᱜᱩᱨᱩ ᱥᱚᱢᱟᱡ ᱵᱷᱟᱞᱚ ᱵᱟᱱᱟᱣ ᱨᱮ ᱢᱟᱨᱟᱝ ᱵᱷᱩᱢᱤᱠᱟ ᱮᱢᱟᱭᱟ।',
      verified: true,
    );

    // ── DEMO MOCK DATASET 2: Paragraph 2 Sentence ─────────────────────────────
    dict.addEntryDirect(
      hindi: 'शिक्षकों का मार्गदर्शन हमारे भविष्य को सही दिशा देता है।',
      santali: 'ᱜᱩᱨᱩ ᱠᱚᱣᱟᱜ ᱞᱟᱦᱟᱱ ᱟᱨ ᱥᱟᱦᱟᱭ ᱟᱢᱟᱜ ᱯᱟᱹᱞᱟᱜ ᱡᱤᱣᱤ ᱠᱟᱹᱞ ᱥᱟᱹᱨᱤ ᱫᱤᱥᱟ ᱮᱢᱟᱭᱟ।',
      verified: true,
    );

    // ── DEMO MOCK DATASET 3: Paragraph 3 Sentences & Full Paragraph ─────────
    dict.addEntryDirect(
      hindi: 'कृपया सभी छात्र अपनी किताबें खोलें और अध्याय तीन पर ध्यान दें।',
      santali: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱡᱚᱛᱚ ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱟᱢᱟᱜ ᱯᱩᱛᱷᱤ ᱠᱚ ᱡᱷᱤᱡ ᱢᱮ ᱟᱨ ᱯᱟᱴᱷ ᱯᱮ ᱨᱮ ᱢᱚᱱ ᱮᱢ ᱢᱮ।',
      verified: true,
    );
    dict.addEntryDirect(
      hindi: 'आज हम एक बहुत ही महत्वपूर्ण विषय पढ़ने जा रहे हैं, इसलिए शांत रहकर ध्यान से सुनें।',
      santali: 'ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱢᱤᱫ ᱟᱹᱰᱤ ᱡᱚᱨᱩᱨᱤ ᱵᱤᱥᱚᱭ ᱥᱤᱠᱷᱟᱣ ᱞᱟᱹᱜᱤᱫ ᱥᱮᱫ ᱮᱢᱟᱭᱟ, ᱚᱱᱟ ᱛᱮ ᱥᱟᱱᱛᱤ ᱛᱮ ᱛᱟᱹᱞᱟ ᱢᱮ ᱟᱨ ᱢᱚᱱ ᱛᱮ ᱟᱧᱡᱚᱢ ᱢᱮ।',
      verified: true,
    );
    dict.addEntryDirect(
      hindi: 'यदि आपके पास कोई प्रश्न है, तो कृपया अपना हाथ उठाएं।',
      santali: 'ᱡᱩᱫᱤ ᱟᱢᱟᱜ ᱡᱟᱦᱟᱱ ᱯᱨᱚᱥᱱᱚ ᱢᱮᱱᱟᱜ ᱠᱟᱱᱟ, ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱟᱢᱟᱜ ᱛᱤ ᱩᱴᱷᱟᱣ ᱢᱮ।',
      verified: true,
    );
    dict.addEntryDirect(
      hindi: 'कृपया सभी छात्र अपनी किताबें खोलें और अध्याय तीन पर ध्यान दें। आज हम एक बहुत ही महत्वपूर्ण विषय पढ़ने जा रहे हैं, इसलिए शांत रहकर ध्यान से सुनें। यदि आपके पास कोई प्रश्न है, तो कृपया अपना हाथ उठाएं।',
      santali: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱡᱚᱛᱚ ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱟᱢᱟᱜ ᱯᱩᱛᱷᱤ ᱠᱚ ᱡᱷᱤᱡ ᱢᱮ ᱟᱨ ᱯᱟᱴᱷ ᱯᱮ ᱨᱮ ᱢᱚᱱ ᱮᱢ ᱢᱮ। ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱢᱤᱫ ᱟᱹᱰᱤ ᱡᱚᱨᱩᱨᱤ ᱵᱤᱥᱚᱭ ᱥᱤᱠᱷᱟᱣ ᱞᱟᱹᱜᱤᱫ ᱥᱮᱫ ᱮᱢᱟᱭᱟ, ᱚᱱᱟ ᱛᱮ ᱥᱟᱱᱛᱤ ᱛᱮ ᱛᱟᱹᱞᱟ ᱢᱮ ᱟᱨ ᱢᱚᱱ ᱛᱮ ᱟᱧᱡᱚᱢ ᱢᱮ। ᱡᱩᱫᱤ ᱟᱢᱟᱜ ᱡᱟᱦᱟᱱ ᱯᱨᱚᱥᱱᱚ ᱢᱮᱱᱟᱜ ᱠᱟᱱᱟ, ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱟᱢᱟᱜ ᱛᱤ ᱩᱴᱷᱟᱣ ᱢᱮ।',
      verified: true,
    );

    // ── DEMO SUB-CLAUSES FOR PARTIAL PHRASE MATCHING ────────────────────────
    dict.addEntryDirect(hindi: 'अपनी किताबें खोलें', santali: 'ᱟᱢᱟᱜ ᱯᱩᱛᱷᱤ ᱠᱚ ᱡᱷᱤᱡ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'अध्याय तीन पर ध्यान दें', santali: 'ᱯᱟᱴᱷ ᱯᱮ ᱨᱮ ᱢᱚᱱ ᱮᱢ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'महत्वपूर्ण विषय', santali: 'ᱡᱚᱨᱩᱨᱤ ᱵᱤᱥᱚᱭ', verified: true);
    dict.addEntryDirect(hindi: 'शांत रहकर ध्यान से सुनें', santali: 'ᱥᱟᱱᱛᱤ ᱛᱮ ᱛᱟᱹᱞᱟ ᱢᱮ ᱟᱨ ᱢᱚᱱ ᱛᱮ ᱟᱧᱡᱚᱢ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'यदि आपके पास कोई प्रश्न है', santali: 'ᱡᱩᱫᱤ ᱟᱢᱟᱜ ᱡᱟᱦᱟᱱ ᱯᱨᱚᱥᱱᱚ ᱢᱮᱱᱟᱜ ᱠᱟᱱᱟ', verified: true);
    dict.addEntryDirect(hindi: 'अपना हाथ उठाएं', santali: 'ᱟᱢᱟᱜ ᱛᱤ ᱩᱴᱷᱟᱣ ᱢᱮ', verified: true);

    // ── CORE VOCABULARY SEED DATA ──────────────────────────────────────────
    dict.addEntryDirect(hindi: 'मेरी बात सुनो', santali: 'ᱤᱧᱟᱜ ᱠᱟᱛᱷᱟ ᱟᱧᱡᱚᱢ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'देखो एक बात सुनो', santali: 'ᱧᱮᱞ ᱢᱮ ᱢᱤᱫᱴᱟᱝ ᱠᱟᱛᱷᱟ ᱟᱧᱡᱚᱢ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'एक बात सुनो', santali: 'ᱢᱤᱫᱴᱟᱝ ᱠᱟᱛᱷᱟ ᱟᱧᱡᱚᱢ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'ध्यान से सुनो', santali: 'ᱢᱚᱱ ᱮᱢ ᱠᱟᱛᱮ ᱟᱧᱡᱚᱢ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'सुनो', santali: 'ᱟᱧᱡᱚᱢ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'सब सुनो', santali: 'ᱟᱧᱡᱚᱢ ᱯᱮ', verified: true);
    dict.addEntryDirect(hindi: 'देखो', santali: 'ᱧᱮᱞ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'सब देखो', santali: 'ᱧᱮᱞ ᱯᱮ', verified: true);
    dict.addEntryDirect(hindi: 'बात', santali: 'ᱠᱟᱛᱷᱟ', verified: true);
    dict.addEntryDirect(hindi: 'मेरी', santali: 'ᱤᱧᱟᱜ', verified: true);
    dict.addEntryDirect(hindi: 'नमस्ते', santali: 'ᱡᱚᱦᱟᱨ', verified: true);
    dict.addEntryDirect(hindi: 'बच्चों', santali: 'ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ', verified: true);
    dict.addEntryDirect(hindi: 'आज हम गणित पढ़ेंगे', santali: 'ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱞᱮᱠᱷᱟ ᱵᱚᱱ ᱯᱟᱲᱦᱟᱣᱟ', verified: true);
    dict.addEntryDirect(hindi: 'बच्चे स्कूल जा रहे हैं', santali: 'ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ ᱤ ᱠᱚ ᱪᱟᱞᱟ ᱠᱟᱱᱟ', verified: true);
    dict.addEntryDirect(hindi: 'पौधे को पानी दो', santali: 'ᱫᱟᱨᱮ ᱨᱮ ᱫᱟ ᱫᱩ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'अपनी किताब खोलो', santali: 'ᱟᱯᱱᱟᱨᱟ ᱯᱩᱛᱷᱤ ᱡᱷᱤ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'साफ पानी पियो', santali: 'ᱥᱟᱯᱷᱟ ᱫᱟᱜ ᱧᱩᱭ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'सब बैठ जाओ', santali: 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱫᱩᱲᱩᱵᱽ ᱯᱮ', verified: true);
    dict.addEntryDirect(hindi: 'बैठो', santali: 'ᱫᱩᱲᱩᱵᱽ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'बैठिए', santali: 'ᱫᱩᱲᱩᱵᱽ ᱵᱤᱱ', verified: true);
    dict.addEntryDirect(hindi: 'खड़े हो जाओ', santali: 'ᱛᱤᱸᱜᱩᱱ ᱢᱮ', verified: true);
    dict.addEntryDirect(hindi: 'सब खड़े हो जाओ', santali: 'ᱡᱚᱛᱚ ᱦᱚᱲ ᱛᱤᱸᱜᱩᱱ ᱯᱮ', verified: true);
    dict.addEntryDirect(hindi: 'गणित', santali: 'ᱞᱮᱠᱷᱟ', verified: true);
    dict.addEntryDirect(hindi: 'किताब', santali: 'ᱯᱩᱛᱷᱤ', verified: true);
    dict.addEntryDirect(hindi: 'पौधा', santali: 'ᱫᱟᱨᱮ', verified: true);
    dict.addEntryDirect(hindi: 'पानी', santali: 'ᱫᱟᱜ', verified: true);
    dict.addEntryDirect(hindi: 'एक', santali: 'ᱢᱤᱫ', verified: true);
    dict.addEntryDirect(hindi: 'दो', santali: 'ᱵᱟᱨ', verified: true);
    dict.addEntryDirect(hindi: 'तीन', santali: 'ᱯᱮ', verified: true);
    dict.addEntryDirect(hindi: 'चार', santali: 'ᱯᱳᱱ', verified: true);
    dict.addEntryDirect(hindi: 'पांच', santali: 'ᱢᱚᱬᱮ', verified: true);
    dict.addEntryDirect(hindi: 'दस', santali: 'ᱜᱮᱞ', verified: true);
    dict.addEntryDirect(hindi: 'साफ', santali: 'ᱥᱟᱯᱷᱟ', verified: true);
    dict.addEntryDirect(hindi: 'स्कूल', santali: 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ', verified: true);
    dict.addEntryDirect(hindi: 'शिक्षक', santali: 'ᱢᱟᱪᱮᱛ', verified: true);
    dict.addEntryDirect(hindi: 'छात्र', santali: 'ᱪᱮᱛᱮᱫᱤᱭᱟᱹ', verified: true);
  }
}
