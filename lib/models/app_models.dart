enum TargetLanguage {
  santhali,
  ho,
  mundari,
}

extension TargetLanguageExtension on TargetLanguage {
  String get displayName {
    switch (this) {
      case TargetLanguage.santhali:
        return 'Santhali (ᱥᱟᱱᱛᱟᱲᱤ)';
      case TargetLanguage.ho:
        return 'Ho (ᱦᱳ)';
      case TargetLanguage.mundari:
        return 'Mundari (मुंडारी)';
    }
  }

  String get code {
    switch (this) {
      case TargetLanguage.santhali:
        return 'santhali';
      case TargetLanguage.ho:
        return 'ho';
      case TargetLanguage.mundari:
        return 'mundari';
    }
  }
}

enum TranslationSource {
  phraseBank,
  astarSearch,
  distilledNmt,
}

extension TranslationSourceExtension on TranslationSource {
  String get label {
    switch (this) {
      case TranslationSource.phraseBank:
        return 'Phrase Bank ⚡';
      case TranslationSource.astarSearch:
        return 'A* Dataset Match 🔍';
      case TranslationSource.distilledNmt:
        return 'Distilled NMT 🤖';
    }
  }
}

class TranslationResult {
  final String originalText;
  final String translatedText;
  final String? phoneticText;
  final TargetLanguage language;
  final TranslationSource source;
  final double latencyMs;
  final DateTime timestamp;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    this.phoneticText,
    required this.language,
    required this.source,
    required this.latencyMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isOriginalSantali {
    return RegExp(r'[\u1C50-\u1C7F]').hasMatch(originalText);
  }
}

class PhraseItem {
  final String id;
  final String category;
  final String hindi;
  final String english;
  final String santhali;
  final String santhaliDevanagari;
  final String ho;
  final String mundari;
  final String phonetic;

  PhraseItem({
    required this.id,
    required this.category,
    required this.hindi,
    required this.english,
    required this.santhali,
    required this.santhaliDevanagari,
    required this.ho,
    required this.mundari,
    required this.phonetic,
  });

  factory PhraseItem.fromJson(Map<String, dynamic> json) {
    return PhraseItem(
      id: json['id'] ?? '',
      category: json['category'] ?? 'General',
      hindi: json['hindi'] ?? '',
      english: json['english'] ?? '',
      santhali: json['santhali'] ?? '',
      santhaliDevanagari: json['santhali_devanagari'] ?? '',
      ho: json['ho'] ?? '',
      mundari: json['mundari'] ?? '',
      phonetic: json['phonetic'] ?? '',
    );
  }

  String getTranslationFor(TargetLanguage lang) {
    switch (lang) {
      case TargetLanguage.santhali:
        return '$santhali\n($santhaliDevanagari)';
      case TargetLanguage.ho:
        return ho;
      case TargetLanguage.mundari:
        return mundari;
    }
  }
}

class FlashcardItem {
  final String id;
  final String hindiWord;
  final String tribalWord;
  final String englishMeaning;
  final String phonetic;
  final String iconSymbol;
  final String exampleSentenceHindi;
  final String exampleSentenceTribal;

  FlashcardItem({
    required this.id,
    required this.hindiWord,
    required this.tribalWord,
    required this.englishMeaning,
    required this.phonetic,
    required this.iconSymbol,
    required this.exampleSentenceHindi,
    required this.exampleSentenceTribal,
  });
}

class UserModel {
  final int? id;
  final String name;
  final String email;
  final bool isVerified;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.isVerified = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'].toString(),
      email: map['email'].toString(),
      isVerified: (map['is_verified'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'is_verified': isVerified ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

