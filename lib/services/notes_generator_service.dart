import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_models.dart';
import 'web_downloader.dart';

class NotesGeneratorService {
  /// Generates the complete classroom session study material document string formatted as a single formal document
  static String generateBilingualDocContent({
    required List<TranslationResult> sessionLogs,
    required TargetLanguage targetLanguage,
    required String lessonTopic,
    required String teacherName,
    String teacherSchool = 'Government Primary School',
    String teacherDesignation = 'Primary Vernacular Teacher',
    String? teacherEmail,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    buffer.writeln('================================================================================');
    buffer.writeln('          NIPUN BHARAT - BILINGUAL CLASSROOM STUDY MATERIAL & LESSON NOTES       ');
    buffer.writeln('================================================================================');
    buffer.writeln('  Date: $dateStr | Time: $timeStr');
    buffer.writeln('  Teacher Name: $teacherName');
    buffer.writeln('  Designation: $teacherDesignation');
    buffer.writeln('  School / Institution: $teacherSchool');
    if (teacherEmail != null && teacherEmail.isNotEmpty) {
      buffer.writeln('  Email: $teacherEmail');
    }
    buffer.writeln('  Lesson Topic: $lessonTopic');
    buffer.writeln('  Target Vernacular Language: ${targetLanguage.displayName} ( Ol Chiki ᱥᱟᱱᱛᱟᱲᱤ & Devanagari संथाली )');
    buffer.writeln('  Pedagogy Framework: NIPUN Bharat Foundational Literacy & Numeracy (FLN)');
    buffer.writeln('================================================================================\n');

    // SECTION 1: SYNOPSIS & EXECUTIVE SUMMARY
    buffer.writeln('1. SYNOPSIS & LESSON EXECUTIVE SUMMARY');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('• Executive Summary: This comprehensive study document consolidates all classroom speech delivered');
    buffer.writeln('  by $teacherName ($teacherDesignation, $teacherSchool) on the topic "$lessonTopic".');
    buffer.writeln('• Total Speech Segments Recorded: ${sessionLogs.length} continuous speech sentences');
    buffer.writeln('• Primary Language Pair: Hindi (Teacher Speech) ➔ Santhali (Vernacular Bridge)');
    buffer.writeln('• Low-Latency AI Pipeline: < 50ms per 5-word real-time sliding window translation.\n');

    // SECTION 2: CLASSROOM LESSON TRANSCRIPT (PARAGRAPH FORMAT & SENTENCE BREAKDOWN)
    buffer.writeln('2. CLASSROOM LESSON TRANSCRIPT');
    buffer.writeln('--------------------------------------------------------------------------------');

    if (sessionLogs.isEmpty) {
      buffer.writeln('[Note: No live speech recorded yet in this classroom session.]\n');
    } else {
      final hindiSentences = sessionLogs
          .map((log) => log.originalText.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final santhaliSentences = sessionLogs
          .map((log) => log.translatedText.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final hindiParagraph = hindiSentences.join(' ');
      final santhaliParagraph = santhaliSentences.join(' ');

      // PART A: UNIFIED PARAGRAPHS
      buffer.writeln('A. UNIFIED HINDI SPEECH PARAGRAPH (शिक्षक वक्तव्य):');
      buffer.writeln('--------------------------------------------------------------------------------');
      buffer.writeln(hindiParagraph.isEmpty ? '[No Hindi speech recorded]' : hindiParagraph);
      buffer.writeln('\n--------------------------------------------------------------------------------\n');

      buffer.writeln('B. UNIFIED SANTHALI TRANSLATION PARAGRAPH (मातृभाषा अनुवाद):');
      buffer.writeln('--------------------------------------------------------------------------------');
      buffer.writeln(santhaliParagraph.isEmpty ? '[No Santhali translation recorded]' : santhaliParagraph);
      buffer.writeln('\n--------------------------------------------------------------------------------\n');

      // PART C: DETAILED SENTENCE-BY-SENTENCE BREAKDOWN
      buffer.writeln('C. DETAILED SENTENCE-BY-SENTENCE BREAKDOWN (क्रमशः वाक्य विवरण):');
      buffer.writeln('--------------------------------------------------------------------------------');
      for (int i = 0; i < sessionLogs.length; i++) {
        final log = sessionLogs[i];
        final sentenceIndex = i + 1;
        final isSantali = log.isOriginalSantali;
        final srcLabel = isSantali ? 'Santhali' : 'Hindi   ';
        final tgtLabel = isSantali ? 'Hindi   ' : 'Santhali';
        buffer.writeln('$sentenceIndex. $srcLabel: ${log.originalText}');
        buffer.writeln('   $tgtLabel: ${log.translatedText}');
        buffer.writeln('--------------------------------------------------------------------------------');
      }
    }

    // SECTION 3: KEY CLASSROOM VOCABULARY & SANTHALI DICTIONARY BANK
    buffer.writeln('\n3. KEY CLASSROOM VOCABULARY & SANTHALI DICTIONARY BANK');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('Hindi Word     | Santhali Translation (Ol Chiki)   | English Meaning | Phonetics');
    buffer.writeln('-------------  | --------------------------------  | --------------- | ---------');
    buffer.writeln('नमस्ते        | ᱡᱚᱦᱟᱨ (जोहार)                     | Greeting        | Johar');
    buffer.writeln('बच्चों         | ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ (गिद्र को)                 | Children        | Gidra ko');
    buffer.writeln('गणित          | ᱞᱮᱠᱷᱟ (लेखा)                     | Mathematics     | Lekha');
    buffer.writeln('किताब         | ᱯᱩᱛᱷᱤ (पुथि)                    | Book            | Puthi');
    buffer.writeln('पौधा          | ᱫᱟᱨᱮ (दारे)                      | Plant           | Dare');
    buffer.writeln('पानी          | ᱫᱟᱜ (दाग)                         | Water           | Dag');
    buffer.writeln('सूरज          | ᱥᱤᱧ (सिंघी)               | Sun             | Singhi');
    buffer.writeln('स्कूल         | ᱤᱛᱩᱱ ᱟᱥᱲᱟ (इतुन असड़ा)             | School          | Itun Asda');
    buffer.writeln('साफ          | ᱥᱟᱯᱷᱟ (साफा)                     | Clean           | Sapha');
    buffer.writeln('शाबाश         | ᱥᱟ (शाबास)                | Excellent       | Sabas');
    buffer.writeln('--------------------------------------------------------------------------------\n');

    // SECTION 4: STUDENT REVISION WORKSHEET & PRACTICE EXERCISES
    buffer.writeln('4. STUDENT REVISION WORKSHEET & PRACTICE EXERCISES');
    buffer.writeln('--------------------------------------------------------------------------------');
    if (sessionLogs.isEmpty) {
      buffer.writeln('[Not enough classroom data to generate dynamic worksheets.]\n');
    } else {
      buffer.writeln('Instructions: Translate the following phrases discussed in class.\n');

      int qNum = 1;
      final questions = sessionLogs.take(5).toList();
      for (final log in questions) {
        final isSantali = log.isOriginalSantali;
        final sourceLang = isSantali ? 'Santhali' : 'Hindi';
        final targetLang = isSantali ? 'Hindi' : 'Santhali';

        buffer.writeln('Q$qNum. Translate this $sourceLang phrase into $targetLang:');
        buffer.writeln('"${log.originalText}"');
        buffer.writeln('\n\n\n');
        qNum++;
      }
    }

    buffer.writeln('================================================================================');
    buffer.writeln('   Generated automatically by Vernacular Pedagogy - Vernacular Bridge System    ');
    buffer.writeln('================================================================================');

    return buffer.toString();
  }

  /// Exports the SINGLE consolidated session study document as a .docx file to local device storage / browser download
  static Future<File> exportSingleDocxFile({
    required List<TranslationResult> sessionLogs,
    required TargetLanguage targetLanguage,
    required String lessonTopic,
    required String teacherName,
    String teacherSchool = 'Government Primary School',
    String teacherDesignation = 'Primary Vernacular Teacher',
    String? teacherEmail,
  }) async {
    final content = generateBilingualDocContent(
      sessionLogs: sessionLogs,
      targetLanguage: targetLanguage,
      lessonTopic: lessonTopic,
      teacherName: teacherName,
      teacherSchool: teacherSchool,
      teacherDesignation: teacherDesignation,
      teacherEmail: teacherEmail,
    );

    final sanitizedTopic = lessonTopic.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    final fileName = 'Complete_Classroom_Study_Material_${sanitizedTopic}_${DateTime.now().millisecondsSinceEpoch}.docx';

    if (kIsWeb) {
      triggerWebBrowserDownload(content: content, fileName: fileName);
      return File(fileName);
    }

    final directory = await getPublicDownloadsDirectory();
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(content);
    return file;
  }

  /// Returns the public Downloads directory on Android mobile & Desktop platforms
  static Future<Directory> getPublicDownloadsDirectory() async {
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final androidDownloadDir = Directory('/storage/emulated/0/Download');
        if (await androidDownloadDir.exists()) {
          return androidDownloadDir;
        } else {
          try {
            await androidDownloadDir.create(recursive: true);
            return androidDownloadDir;
          } catch (_) {}
        }
      }
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          return downloadsDir;
        }
      } catch (e) {
        debugPrint('[NotesGeneratorService] getDownloadsDirectory failed: $e');
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  static Future<File> downloadBilingualNotesDocx({
    required List<TranslationResult> logs,
    required String lessonTopic,
    required String teacherName,
    String teacherSchool = 'Government Primary School',
    String teacherDesignation = 'Primary Vernacular Teacher',
    String? teacherEmail,
    TargetLanguage targetLanguage = TargetLanguage.santhali,
  }) {
    return exportSingleDocxFile(
      sessionLogs: logs,
      targetLanguage: targetLanguage,
      lessonTopic: lessonTopic,
      teacherName: teacherName,
      teacherSchool: teacherSchool,
      teacherDesignation: teacherDesignation,
      teacherEmail: teacherEmail,
    );
  }

  static Future<File> exportTxtFile({
    required List<TranslationResult> sessionLogs,
    required TargetLanguage targetLanguage,
    required String lessonTopic,
    required String teacherName,
    String teacherSchool = 'Government Primary School',
    String teacherDesignation = 'Primary Vernacular Teacher',
    String? teacherEmail,
  }) async {
    final content = generateBilingualDocContent(
      sessionLogs: sessionLogs,
      targetLanguage: targetLanguage,
      lessonTopic: lessonTopic,
      teacherName: teacherName,
      teacherSchool: teacherSchool,
      teacherDesignation: teacherDesignation,
      teacherEmail: teacherEmail,
    );

    final sanitizedTopic = lessonTopic.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    final fileName = 'Complete_Classroom_Study_Material_${sanitizedTopic}_${DateTime.now().millisecondsSinceEpoch}.txt';

    if (kIsWeb) {
      triggerWebBrowserDownload(content: content, fileName: fileName);
      return File(fileName);
    }

    final directory = await getPublicDownloadsDirectory();
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(content);
    return file;
  }

  static String? _activeLiveTxtPath;

  /// Continuously appends live speech text & translation to a single live notes file (.txt)
  static Future<File> appendSpeechToLiveNotesFile({
    required String hindiText,
    required String translatedText,
    required TargetLanguage targetLanguage,
    required String lessonTopic,
    required String teacherName,
    String teacherSchool = 'Government Primary School',
    String teacherDesignation = 'Primary Vernacular Teacher',
  }) async {
    if (kIsWeb) {
      _activeLiveTxtPath = 'Live_Hindi_Classroom_Notes.txt';
      return File(_activeLiveTxtPath!);
    }

    final directory = await getPublicDownloadsDirectory();
    final file = File('${directory.path}/Live_Hindi_Classroom_Notes.txt');
    _activeLiveTxtPath = file.path;

    if (!await file.exists()) {
      final header = '''================================================================================
NIPUN BHARAT - REAL-TIME CONTINUOUS CLASSROOM HINDI SPEECH NOTES
Teacher: $teacherName ($teacherDesignation, $teacherSchool)
Topic: $lessonTopic
Target Vernacular Language: ${targetLanguage.displayName}
================================================================================\n\n''';
      await file.writeAsString(header, flush: true);
    }

    final entry = '$hindiText ';
    await file.writeAsString(entry, mode: FileMode.append, flush: true);
    return file;
  }

  static String? get activeLiveTxtPath => _activeLiveTxtPath;

  static Future<File> downloadLiveHindiNotesTxt({
    required List<TranslationResult> sessionLogs,
    required TargetLanguage targetLanguage,
    required String lessonTopic,
    required String teacherName,
    String teacherSchool = 'Government Primary School',
    String teacherDesignation = 'Primary Vernacular Teacher',
    String? teacherEmail,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('================================================================================');
    buffer.writeln('          CONTINUOUS HINDI CLASSROOM SPEECH NOTES (.TXT)                       ');
    buffer.writeln('================================================================================');
    buffer.writeln('Teacher: $teacherName');
    buffer.writeln('Designation: $teacherDesignation');
    buffer.writeln('School / Institution: $teacherSchool');
    if (teacherEmail != null && teacherEmail.isNotEmpty) {
      buffer.writeln('Email: $teacherEmail');
    }
    buffer.writeln('Topic: $lessonTopic');
    buffer.writeln('Target Language: ${targetLanguage.displayName}');
    buffer.writeln('================================================================================\n');

    final hindiSentences = sessionLogs
        .map((log) => log.originalText.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final santhaliSentences = sessionLogs
        .map((log) => log.translatedText.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final hindiParagraph = hindiSentences.join(' ');
    final santhaliParagraph = santhaliSentences.join(' ');

    buffer.writeln('PART 1: UNIFIED PARAGRAPH FORMAT');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('HINDI SPEECH PARAGRAPH (शिक्षक वक्तव्य):');
    buffer.writeln(hindiParagraph.isEmpty ? '[No Hindi speech recorded]' : hindiParagraph);
    buffer.writeln('\n--------------------------------------------------------------------------------\n');

    buffer.writeln('${targetLanguage.displayName.toUpperCase()} TRANSLATION PARAGRAPH (मातृभाषा अनुवाद):');
    buffer.writeln(santhaliParagraph.isEmpty ? '[No Santhali translation recorded]' : santhaliParagraph);
    buffer.writeln('\n================================================================================\n');

    buffer.writeln('PART 2: DETAILED SENTENCE-BY-SENTENCE BREAKDOWN');
    buffer.writeln('--------------------------------------------------------------------------------');
    for (int i = 0; i < sessionLogs.length; i++) {
      final log = sessionLogs[i];
      final isSantali = log.isOriginalSantali;
      final srcLabel = isSantali ? 'Santhali' : 'Hindi';
      final tgtLabel = isSantali ? 'Hindi' : targetLanguage.displayName;
      buffer.writeln('${i + 1}. $srcLabel: ${log.originalText}');
      buffer.writeln('   $tgtLabel: ${log.translatedText}');
      buffer.writeln('--------------------------------------------------------------------------------');
    }

    final content = buffer.toString();
    final fileName = 'Live_Hindi_Classroom_Notes_${DateTime.now().millisecondsSinceEpoch}.txt';

    if (kIsWeb) {
      triggerWebBrowserDownload(content: content, fileName: fileName);
      return File(fileName);
    }

    final directory = await getPublicDownloadsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content, flush: true);
    return file;
  }

  static Future<void> clearLiveNotesFile() async {
    _activeLiveTxtPath = null;
    if (!kIsWeb) {
      try {
        final directory = await getPublicDownloadsDirectory();
        final file = File('${directory.path}/Live_Hindi_Classroom_Notes.txt');
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  static Future<File> exportDocxFile({
    required List<TranslationResult> sessionLogs,
    required TargetLanguage targetLanguage,
    required String lessonTopic,
    required String teacherName,
    String teacherSchool = 'Government Primary School',
    String teacherDesignation = 'Primary Vernacular Teacher',
    String? teacherEmail,
  }) {
    return exportSingleDocxFile(
      sessionLogs: sessionLogs,
      targetLanguage: targetLanguage,
      lessonTopic: lessonTopic,
      teacherName: teacherName,
      teacherSchool: teacherSchool,
      teacherDesignation: teacherDesignation,
      teacherEmail: teacherEmail,
    );
  }
}
