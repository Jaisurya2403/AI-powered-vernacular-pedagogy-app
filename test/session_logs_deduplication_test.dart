import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vernacular_pedagogy/models/app_models.dart';
import 'package:vernacular_pedagogy/services/db_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DbHelper Session Logs Deduplication & Superset Replacement Tests', () {
    setUp(() async {
      await DbHelper.clearSessionLogsFromDb();
    });

    test('Replaces partial half-sentence with full expanded sentence (Superset Replacement)', () async {
      // 1. First partial flush (17 words)
      final partialResult = TranslationResult(
        originalText: 'सुबह के साथ बजे हैं और धूप निकल आया है में हर रोज सुबह जल्दी उठना हो',
        translatedText: '[सुबह] [के] [साथ] [बजे] [हैं] [और] [धूप] [निकल] [आया] [है]',
        language: TargetLanguage.santhali,
        source: TranslationSource.phraseBank,
        latencyMs: 12.0,
      );
      await DbHelper.saveSessionLogToDb(partialResult);

      List<TranslationResult> logs = await DbHelper.fetchSessionLogsFromDb();
      expect(logs.length, 1);
      expect(logs.first.originalText.contains('उठना हो'), true);

      // 2. Full sentence expansion (22 words - includes "और यह क्लास गर्म पानी पीता हूं")
      final fullResult = TranslationResult(
        originalText:
            'सुबह के साथ बजे हैं और धूप निकल आया है में हर रोज सुबह जल्दी उठना हो और यह क्लास गर्म पानी पीता हूं',
        translatedText:
            '[सुबह] [के] [साथ] [बजे] [हैं] [और] [धूप] [निकल] [आया] [है] [में] [हर] [रोज] [सुबह] [जल्दी] [उठना] [हो] [और] [यह] [क्लास] [गर्म] ᱫᱟᱜ (दाग) [पीता] [हूं]',
        language: TargetLanguage.santhali,
        source: TranslationSource.phraseBank,
        latencyMs: 12.0,
      );
      await DbHelper.saveSessionLogToDb(fullResult);

      logs = await DbHelper.fetchSessionLogsFromDb();
      // MUST STILL BE EXACTLY 1 ROW (replaced, not duplicated!)
      expect(logs.length, 1);
      expect(logs.first.originalText.contains('गर्म पानी पीता हूं'), true);

      // 3. STT auto-restart re-emits partial 17 words again
      await DbHelper.saveSessionLogToDb(partialResult);
      logs = await DbHelper.fetchSessionLogsFromDb();

      // MUST STILL BE EXACTLY 1 ROW (re-emission discarded!)
      expect(logs.length, 1);
      expect(logs.first.originalText.contains('गर्म पानी पीता हूं'), true);
    });

    test('Appends distinct new sentence in chronological order', () async {
      final sentence1 = TranslationResult(
        originalText: 'सुबह के साथ बजे हैं और धूप निकल आया है',
        translatedText: '[सुबह] [के] [साथ] [बजे] [हैं]',
        language: TargetLanguage.santhali,
        source: TranslationSource.phraseBank,
        latencyMs: 10.0,
      );
      await DbHelper.saveSessionLogToDb(sentence1);

      final sentence2 = TranslationResult(
        originalText: 'आज हम गणित का नया अध्याय शुरू करेंगे',
        translatedText: '[आज] [हम] ᱞᱮᱠᱷᱟ (लेखा) [अध्याय] [शुरू] [करेंगे]',
        language: TargetLanguage.santhali,
        source: TranslationSource.phraseBank,
        latencyMs: 15.0,
      );
      await DbHelper.saveSessionLogToDb(sentence2);

      final logs = await DbHelper.fetchSessionLogsFromDb();
      expect(logs.length, 2);
      expect(logs[0].originalText, sentence1.originalText);
      expect(logs[1].originalText, sentence2.originalText);
    });
  });
}
