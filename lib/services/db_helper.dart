import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/app_models.dart';
import 'db_factory.dart';

class DbHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    setupDatabaseFactory();

    final path = kIsWeb ? 'vernacular_pedagogy.db' : join(await getDatabasesPath(), 'vernacular_pedagogy.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTablesAndSeed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTablesAndSeed(db);
      },
      onOpen: (db) async {
        await _createTablesAndSeed(db);
      },
    );

  }

  static Future<void> _createTablesAndSeed(Database db) async {
    // 1. Users Table (Auth with school/designation)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        school TEXT DEFAULT 'Government Primary School',
        designation TEXT DEFAULT 'Primary Vernacular Teacher',
        password_hash TEXT NOT NULL,
        is_verified INTEGER DEFAULT 0,
        has_voiceprint INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // 2. App Settings / Persistent Session Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // 3. Voiceprints Table (Acoustic biometric embeddings)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS voiceprints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_id INTEGER NOT NULL UNIQUE,
        embedding TEXT NOT NULL,
        sample_count INTEGER NOT NULL DEFAULT 1,
        prompt_text TEXT,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 4. Teaching Sessions History Table (Date-wise structured logs)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS teaching_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        topic TEXT NOT NULL,
        teacher_name TEXT NOT NULL,
        target_language TEXT NOT NULL,
        date_str TEXT NOT NULL,
        time_str TEXT NOT NULL,
        total_sentences INTEGER DEFAULT 0,
        notes_file_path TEXT,
        docx_file_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 5. Teachers Table (§5 Legacy Schema compatibility)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        school TEXT,
        password_hash TEXT NOT NULL,
        is_email_verified INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 6. Flashcards Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS flashcards (
        id TEXT PRIMARY KEY,
        hindi_word TEXT NOT NULL,
        tribal_word TEXT NOT NULL,
        english_meaning TEXT,
        phonetic TEXT,
        icon_symbol TEXT,
        example_hindi TEXT,
        example_tribal TEXT,
        curriculum_unit_id INTEGER
      )
    ''');

    // 7. Phrase Bank Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS phrase_bank (
        id TEXT PRIMARY KEY,
        category TEXT,
        hindi TEXT,
        english TEXT,
        santhali TEXT,
        santhali_devanagari TEXT,
        ho TEXT,
        mundari TEXT,
        phonetic TEXT
      )
    ''');

    // 8. Word Dictionary Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS word_dictionary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hindi_word TEXT NOT NULL,
        tribal_word TEXT NOT NULL,
        language TEXT NOT NULL,
        phonetic TEXT
      )
    ''');

    // 9. Session Conversation Logs Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        session_id INTEGER,
        original_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        phonetic_text TEXT,
        language TEXT NOT NULL,
        source TEXT NOT NULL,
        latency_ms REAL NOT NULL,
        created_at TEXT
      )
    ''');

    // Safe column migrations for pre-existing SQLite database versions
    try {
      await db.execute('ALTER TABLE users ADD COLUMN school TEXT DEFAULT "Government Primary School"');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE users ADD COLUMN designation TEXT DEFAULT "Primary Vernacular Teacher"');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE users ADD COLUMN has_voiceprint INTEGER DEFAULT 0');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE session_logs ADD COLUMN user_id INTEGER');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE session_logs ADD COLUMN session_id INTEGER');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE voiceprints ADD COLUMN prompt_text TEXT');
    } catch (_) {}

    // Seed initial data into SQLite Database
    await _seedDatabase(db);
  }


  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<void> _seedDatabase(Database db) async {
    try {
      // Check if already seeded
      final existingPhrases = await db.query('phrase_bank', limit: 1);
      if (existingPhrases.isNotEmpty) return;

      // Seed Phrase Bank from JSON asset
      final phraseJsonStr = await rootBundle.loadString('assets/phrase_bank/classroom_phrases.json');
      final phraseData = json.decode(phraseJsonStr) as Map<String, dynamic>;
      final phraseList = phraseData['phrases'] as List<dynamic>;

      for (var item in phraseList) {
        final map = item as Map<String, dynamic>;
        await db.insert(
          'phrase_bank',
          {
            'id': map['id'],
            'category': map['category'],
            'hindi': map['hindi'],
            'english': map['english'],
            'santhali': map['santhali'],
            'santhali_devanagari': map['santhali_devanagari'],
            'ho': map['ho'],
            'mundari': map['mundari'],
            'phonetic': map['phonetic'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Seed Santhali Dataset from JSON asset
      final santhaliJsonStr = await rootBundle.loadString('assets/datasets/hindi_santhali_dataset.json');
      final santhaliData = json.decode(santhaliJsonStr) as Map<String, dynamic>;
      final dictMap = santhaliData['word_dictionary'] as Map<String, dynamic>;

      for (var entry in dictMap.entries) {
        await db.insert('word_dictionary', {
          'hindi_word': entry.key,
          'tribal_word': entry.value.toString(),
          'language': 'santhali',
          'phonetic': entry.value.toString(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Seed Flashcards from default data
      final initialFlashcards = [
        {'id': 'fc01', 'hindi_word': 'गणित', 'tribal_word': 'ᱞᱮᱠᱷᱟ (लेखा)', 'english_meaning': 'Mathematics', 'phonetic': 'Lekha', 'icon_symbol': '🔢', 'example_hindi': 'आज हम गणित सीखेंगे।', 'example_tribal': 'ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱞᱮᱠᱷᱟ ᱵᱚᱱ ᱪᱮᱫᱟ᱾'},
        {'id': 'fc02', 'hindi_word': 'गिनती (१-१०)', 'tribal_word': 'ᱢᱤᱫ ᱠᱷᱚᱱ ᱜᱮᱞ (मिद खोन गेल)', 'english_meaning': 'Counting 1 to 10', 'phonetic': 'Mid khon gel', 'icon_symbol': '🧮', 'example_hindi': 'एक से दस तक गिनती करो।', 'example_tribal': 'ᱢᱤᱫ ᱠᱷᱚᱱ ᱜᱮᱞ ᱦᱟᱹᱵᱤᱡ ᱞᱮᱠᱷᱟᱭ ᱢᱮ᱾'},
        {'id': 'fc03', 'hindi_word': 'पौधा', 'tribal_word': 'ᱫᱟᱨᱮ (दारे)', 'english_meaning': 'Plant', 'phonetic': 'Dare', 'icon_symbol': '🌱', 'example_hindi': 'पौधे को पानी दो।', 'example_tribal': 'ᱫᱟᱨᱮ ᱨᱮ ᱫᱟᱜ ᱫᱩᱞ ᱢᱮ᱾'},
        {'id': 'fc04', 'hindi_word': 'किताब', 'tribal_word': 'ᱯᱩᱛᱷᱤ (पुथि)', 'english_meaning': 'Book', 'phonetic': 'Puthi', 'icon_symbol': '📖', 'example_hindi': 'अपनी किताब खोलो।', 'example_tribal': 'ᱟᱯᱱᱟᱨᱟᱜ ᱯᱩᱛᱷᱤ ᱡᱷᱤᱡᱽ ᱢᱮ᱾'},
        {'id': 'fc05', 'hindi_word': 'पानी', 'tribal_word': 'ᱫᱟᱜ (दाग)', 'english_meaning': 'Water', 'phonetic': 'Dag', 'icon_symbol': '💧', 'example_hindi': 'साफ पानी पीना चाहिए।', 'example_tribal': 'ᱥᱟᱯᱷᱟ ᱫᱟᱜ ᱧᱩ ᱞᱟᱹᱠᱛᱤ vertical.'},
        {'id': 'fc06', 'hindi_word': 'सूरज', 'tribal_word': 'ᱥᱤᱧ (सिंघी)', 'english_meaning': 'Sun', 'phonetic': 'Singhi', 'icon_symbol': '☀️', 'example_hindi': 'सूरज पूरब में उगता है।', 'example_tribal': 'ᱥᱤᱧ ᱥᱟᱢᱟᱝ ᱨᱮ ᱨᱟᱠᱟᱵ-ᱟ᱾'},
        {'id': 'fc07', 'hindi_word': 'स्कूल', 'tribal_word': 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ (इतुन असड़ा)', 'english_meaning': 'School', 'phonetic': 'Itun Asda', 'icon_symbol': '🏫', 'example_hindi': 'बच्चे स्कूल जा रहे हैं।', 'example_tribal': 'ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ ᱤᱛᱩᱱ ᱟᱥᱲᱟ ᱠᱚ ᱪᱟᱞᱟ structure ᱠᱟᱱᱟ᱾'},
        {'id': 'fc08', 'hindi_word': 'शिक्षक', 'tribal_word': 'ᱢᱟᱪᱮᱛ (माचेत)', 'english_meaning': 'Teacher', 'phonetic': 'Machet', 'icon_symbol': '👨‍🏫', 'example_hindi': 'शिक्षक पाठ पढ़ाते हैं।', 'example_tribal': 'ᱢᱟᱪᱮᱛ ᱯᱟᱴᱷ ᱯᱟᱲᱦᱟᱣᱟᱭ᱾'},
      ];

      for (var fc in initialFlashcards) {
        await db.insert('flashcards', fc, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      debugPrint('[SQLite] Database successfully created and seeded!');
    } catch (e) {
      debugPrint('[SQLite Seed Error] $e');
    }
  }

  // --- PERSISTENT AUTH & ACTIVE USER SESSION ---

  static Future<void> setActiveUserSession(String email) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': 'active_user_email', 'value': email.trim().toLowerCase()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getActiveUserSession() async {
    final db = await database;
    final results = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['active_user_email'],
    );
    if (results.isNotEmpty) {
      return results.first['value']?.toString();
    }
    return null;
  }

  static Future<void> clearActiveUserSession() async {
    final db = await database;
    await db.delete('app_settings', where: 'key = ?', whereArgs: ['active_user_email']);
  }

  // --- AUTHENTICATION SQLITE OPERATIONS ---

  static Future<int> registerUser({
    required String name,
    required String email,
    required String password,
    String school = 'Government Primary School',
    String designation = 'Primary Vernacular Teacher',
  }) async {
    final db = await database;
    final passwordHash = _hashPassword(password);
    return await db.insert('users', {
      'name': name,
      'email': email.trim().toLowerCase(),
      'school': school,
      'designation': designation,
      'password_hash': passwordHash,
      'is_verified': 0,
      'has_voiceprint': 0,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }


  static Future<void> markUserVerified(String email) async {
    final db = await database;
    await db.update(
      'users',
      {'is_verified': 1},
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final passwordHash = _hashPassword(password);
    final results = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.trim().toLowerCase(), passwordHash],
    );

    if (results.isNotEmpty) {
      await setActiveUserSession(email);
      return results.first;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  static Future<bool> updateUserProfile({
    required int userId,
    required String name,
    required String school,
    String? designation,
  }) async {
    final db = await database;
    final count = await db.update(
      'users',
      {
        'name': name.trim(),
        'school': school.trim(),
        if (designation != null) 'designation': designation.trim(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  static Future<bool> updatePassword({
    required String email,
    required String newPassword,
  }) async {
    final db = await database;
    final newHash = _hashPassword(newPassword);
    final count = await db.update(
      'users',
      {'password_hash': newHash},
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    return count > 0;
  }

  // --- VOICEPRINT BIOMETRICS SQLITE OPERATIONS ---

  static Future<void> saveVoiceprint(VoiceprintModel voiceprint) async {
    final db = await database;
    await db.insert(
      'voiceprints',
      {
        'teacher_id': voiceprint.userId,
        'embedding': voiceprint.embedding,
        'sample_count': voiceprint.sampleCount,
        'prompt_text': voiceprint.promptText,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update user flag
    await db.update(
      'users',
      {'has_voiceprint': 1},
      where: 'id = ?',
      whereArgs: [voiceprint.userId],
    );
  }

  static Future<VoiceprintModel?> getVoiceprintForUser(int userId) async {
    final db = await database;
    final results = await db.query(
      'voiceprints',
      where: 'teacher_id = ?',
      whereArgs: [userId],
    );

    if (results.isNotEmpty) {
      return VoiceprintModel.fromMap(results.first);
    }
    return null;
  }

  static Future<void> deleteVoiceprint(int userId) async {
    final db = await database;
    await db.delete('voiceprints', where: 'teacher_id = ?', whereArgs: [userId]);
    await db.update('users', {'has_voiceprint': 0}, where: 'id = ?', whereArgs: [userId]);
  }

  // --- TEACHING SESSIONS HISTORY SQLITE OPERATIONS ---

  static Future<int> saveTeachingSession(TeachingSessionModel session) async {
    final db = await database;
    return await db.insert(
      'teaching_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<TeachingSessionModel>> fetchTeachingSessionsForUser(int? userId) async {
    final db = await database;
    final results = userId != null
        ? await db.query('teaching_sessions', where: 'user_id = ?', whereArgs: [userId], orderBy: 'id DESC')
        : await db.query('teaching_sessions', orderBy: 'id DESC');

    return results.map((map) => TeachingSessionModel.fromMap(map)).toList();
  }

  static Future<void> deleteTeachingSession(int sessionId) async {
    final db = await database;
    await db.delete('teaching_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  // --- DYNAMIC DATA FETCHING FROM SQLITE ---

  static Future<List<PhraseItem>> fetchPhraseBankFromDb() async {
    final db = await database;
    final results = await db.query('phrase_bank');

    return results.map((map) {
      return PhraseItem(
        id: map['id'].toString(),
        category: map['category'].toString(),
        hindi: map['hindi'].toString(),
        english: map['english'].toString(),
        santhali: map['santhali'].toString(),
        santhaliDevanagari: map['santhali_devanagari'].toString(),
        ho: map['ho'].toString(),
        mundari: map['mundari'].toString(),
        phonetic: map['phonetic'].toString(),
      );
    }).toList();
  }

  static Future<Map<String, String>> fetchWordDictionaryFromDb(String language) async {
    final db = await database;
    final results = await db.query(
      'word_dictionary',
      where: 'language = ?',
      whereArgs: [language.toLowerCase()],
    );

    final map = <String, String>{};
    for (var row in results) {
      map[row['hindi_word'].toString()] = row['tribal_word'].toString();
    }
    return map;
  }

  static Future<List<FlashcardItem>> fetchFlashcardsFromDb() async {
    final db = await database;
    final results = await db.query('flashcards');

    return results.map((map) {
      return FlashcardItem(
        id: map['id'].toString(),
        hindiWord: map['hindi_word'].toString(),
        tribalWord: map['tribal_word'].toString(),
        englishMeaning: map['english_meaning'].toString(),
        phonetic: map['phonetic'].toString(),
        iconSymbol: map['icon_symbol'].toString(),
        exampleSentenceHindi: map['example_hindi'].toString(),
        exampleSentenceTribal: map['example_tribal'].toString(),
      );
    }).toList();
  }

  static Future<void> saveSessionLogToDb(TranslationResult log, {int? userId, int? sessionId}) async {
    final db = await database;

    final cleanInput = log.originalText.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleanInput.isEmpty) return;

    final inputKey = cleanInput.replaceAll(RegExp(r'[\s\.\।\?!\n,;\-]'), '').toLowerCase();

    // Fetch existing session logs in chronological order
    final existingRows = await db.query('session_logs', orderBy: 'id ASC');

    if (existingRows.isNotEmpty) {
      final lastRow = existingRows.last;
      final lastId = lastRow['id'] as int;
      final lastOriginal = lastRow['original_text'].toString().trim().replaceAll(RegExp(r'\s+'), ' ');
      final lastKey = lastOriginal.replaceAll(RegExp(r'[\s\.\।\?!\n,;\-]'), '').toLowerCase();

      // 1. Exact match with last entry -> Skip
      if (inputKey == lastKey) return;

      // 2. New input is a longer superset / expansion of the immediate last entry -> Update last entry in DB
      if (inputKey.startsWith(lastKey) || inputKey.contains(lastKey)) {
        if (inputKey.length > lastKey.length) {
          await db.update(
            'session_logs',
            {
              'original_text': log.originalText,
              'translated_text': log.translatedText,
              'phonetic_text': log.phoneticText ?? '',
              'language': log.language.displayName,
              'source': log.source.label,
              'latency_ms': log.latencyMs,
              'created_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [lastId],
          );
          return;
        } else {
          // Shorter partial re-emission of last entry -> Skip
          return;
        }
      }

      // 3. Last entry is a superset of new input -> Skip
      if (lastKey.startsWith(inputKey) || lastKey.contains(inputKey)) {
        return;
      }
    }

    // 4. Insert as a new row in session logs
    await db.insert('session_logs', {
      'user_id': userId,
      'session_id': sessionId,
      'original_text': log.originalText,
      'translated_text': log.translatedText,
      'phonetic_text': log.phoneticText ?? '',
      'language': log.language.displayName,
      'source': log.source.label,
      'latency_ms': log.latencyMs,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<TranslationResult>> fetchSessionLogsFromDb({int? userId}) async {
    final db = await database;
    final results = await db.query('session_logs', orderBy: 'id ASC');

    return results.map((map) {
      return TranslationResult(
        originalText: map['original_text'].toString(),
        translatedText: map['translated_text'].toString(),
        phoneticText: map['phonetic_text'].toString(),
        language: TargetLanguage.santhali,
        source: TranslationSource.phraseBank,
        latencyMs: (map['latency_ms'] as num?)?.toDouble() ?? 12.0,
      );
    }).toList();
  }

  static Future<void> clearSessionLogsFromDb() async {
    final db = await database;
    await db.delete('session_logs');
  }
}
