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
  final String school;
  final String designation;
  final bool isVerified;
  final bool hasVoiceprint;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.school = 'Government Primary School',
    this.designation = 'Primary Vernacular Teacher',
    this.isVerified = false,
    this.hasVoiceprint = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'].toString(),
      email: map['email'].toString(),
      school: map['school']?.toString() ?? 'Government Primary School',
      designation: map['designation']?.toString() ?? 'Primary Vernacular Teacher',
      isVerified: (map['is_verified'] as int?) == 1 || (map['is_email_verified'] as int?) == 1,
      hasVoiceprint: (map['has_voiceprint'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'school': school,
      'designation': designation,
      'is_verified': isVerified ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? school,
    String? designation,
    bool? isVerified,
    bool? hasVoiceprint,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      school: school ?? this.school,
      designation: designation ?? this.designation,
      isVerified: isVerified ?? this.isVerified,
      hasVoiceprint: hasVoiceprint ?? this.hasVoiceprint,
      createdAt: createdAt,
    );
  }
}

class VoiceprintModel {
  final int? id;
  final int userId;
  final String embedding; // JSON-encoded vector
  final int sampleCount;
  final DateTime updatedAt;
  final String promptText;

  VoiceprintModel({
    this.id,
    required this.userId,
    required this.embedding,
    this.sampleCount = 1,
    DateTime? updatedAt,
    this.promptText = 'नमस्ते बच्चों, आज हम कक्षा में पाठ पढ़ेंगे।',
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory VoiceprintModel.fromMap(Map<String, dynamic> map) {
    return VoiceprintModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? map['teacher_id'] as int? ?? 1,
      embedding: map['embedding']?.toString() ?? '[]',
      sampleCount: map['sample_count'] as int? ?? 1,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      promptText: map['prompt_text']?.toString() ?? 'नमस्ते बच्चों, आज हम कक्षा में पाठ पढ़ेंगे।',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'teacher_id': userId,
      'embedding': embedding,
      'sample_count': sampleCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class VoiceMatchResult {
  final bool isMatched;
  final double similarityScore; // 0.0 - 1.0
  final String confidenceLabel;
  final bool isEnrolled;
  final String teacherName;

  VoiceMatchResult({
    required this.isMatched,
    required this.similarityScore,
    required this.confidenceLabel,
    this.isEnrolled = true,
    this.teacherName = 'Teacher',
  });
}

class TeachingSessionModel {
  final int? id;
  final int? userId;
  final String topic;
  final String teacherName;
  final String targetLanguage;
  final String dateStr;
  final String timeStr;
  final int totalSentences;
  final String? notesFilePath;
  final String? docxFilePath;
  final DateTime createdAt;
  final List<TranslationResult> sessionLogs;

  TeachingSessionModel({
    this.id,
    this.userId,
    required this.topic,
    required this.teacherName,
    required this.targetLanguage,
    required this.dateStr,
    required this.timeStr,
    required this.totalSentences,
    this.notesFilePath,
    this.docxFilePath,
    DateTime? createdAt,
    this.sessionLogs = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  factory TeachingSessionModel.fromMap(Map<String, dynamic> map) {
    return TeachingSessionModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? map['teacher_id'] as int?,
      topic: map['topic']?.toString() ?? map['class_name']?.toString() ?? 'Classroom Lesson',
      teacherName: map['teacher_name']?.toString() ?? 'Teacher',
      targetLanguage: map['target_language']?.toString() ?? 'Santhali',
      dateStr: map['date_str']?.toString() ?? '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      timeStr: map['time_str']?.toString() ?? '${DateTime.now().hour}:${DateTime.now().minute}',
      totalSentences: map['total_sentences'] as int? ?? 0,
      notesFilePath: map['notes_file_path']?.toString(),
      docxFilePath: map['docx_file_path']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'topic': topic,
      'teacher_name': teacherName,
      'target_language': targetLanguage,
      'date_str': dateStr,
      'time_str': timeStr,
      'total_sentences': totalSentences,
      'notes_file_path': notesFilePath,
      'docx_file_path': docxFilePath,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
