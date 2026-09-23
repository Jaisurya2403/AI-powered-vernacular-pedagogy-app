import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/app_models.dart';

class DatasetService {
  final Map<String, PhraseItem> _phraseBank = {};
  final Map<TargetLanguage, Map<String, String>> _wordDictionaries = {
    TargetLanguage.santhali: {},
    TargetLanguage.ho: {},
    TargetLanguage.mundari: {},
  };

  final Map<TargetLanguage, List<Map<String, String>>> _parallelCorpora = {
    TargetLanguage.santhali: [],
    TargetLanguage.ho: [],
    TargetLanguage.mundari: [],
  };

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Map<String, PhraseItem> get phraseBank => _phraseBank;

  Map<String, String> getDictionary(TargetLanguage lang) {
    return _wordDictionaries[lang] ?? {};
  }

  List<Map<String, String>> getParallelCorpus(TargetLanguage lang) {
    return _parallelCorpora[lang] ?? [];
  }

  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      // 1. Load Phrase Bank
      final phraseBankJsonStr = await rootBundle.loadString('assets/phrase_bank/classroom_phrases.json');
      final phraseMap = json.decode(phraseBankJsonStr) as Map<String, dynamic>;
      final phraseList = phraseMap['phrases'] as List<dynamic>;

      _phraseBank.clear();
      for (var item in phraseList) {
        final phrase = PhraseItem.fromJson(item as Map<String, dynamic>);
        _phraseBank[phrase.id] = phrase;
      }

      // 2. Load Santhali Dataset
      await _loadDatasetFile('assets/datasets/hindi_santhali_dataset.json', TargetLanguage.santhali);

      // 3. Load Ho Dataset
      await _loadDatasetFile('assets/datasets/hindi_ho_dataset.json', TargetLanguage.ho);

      // 4. Load Mundari Dataset
      await _loadDatasetFile('assets/datasets/hindi_mundari_dataset.json', TargetLanguage.mundari);

      _isLoaded = true;
    } catch (e) {
      // Handle asset load error gracefully
      _isLoaded = true;
    }
  }

  Future<void> _loadDatasetFile(String path, TargetLanguage lang) async {
    try {
      final jsonStr = await rootBundle.loadString(path);
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      if (data.containsKey('word_dictionary')) {
        final dict = Map<String, String>.from(data['word_dictionary']);
        _wordDictionaries[lang]!.addAll(dict);
      }

      if (data.containsKey('parallel_corpus')) {
        final corpus = (data['parallel_corpus'] as List<dynamic>)
            .map((e) => Map<String, String>.from(e))
            .toList();
        _parallelCorpora[lang]!.addAll(corpus);
      }
    } catch (_) {}
  }

  /// Allows user to dynamically import custom JSON datasets from local storage
  void importCustomDatasetJson(String rawJson, TargetLanguage lang) {
    try {
      final data = json.decode(rawJson) as Map<String, dynamic>;
      if (data.containsKey('word_dictionary')) {
        final dict = Map<String, String>.from(data['word_dictionary']);
        _wordDictionaries[lang]!.addAll(dict);
      }
      if (data.containsKey('parallel_corpus')) {
        final corpus = (data['parallel_corpus'] as List<dynamic>)
            .map((e) => Map<String, String>.from(e))
            .toList();
        _parallelCorpora[lang]!.addAll(corpus);
      }
    } catch (e) {
      rethrow;
    }
  }
}
