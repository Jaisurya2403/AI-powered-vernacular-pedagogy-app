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
      version: 1,
      onCreate: (db, version) async {
        await _createTablesAndSeed(db);
      },
    );
  }

  static Future<void> _createTablesAndSeed(Database db) async {
        // 1. Users Table
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            is_verified INTEGER DEFAULT 0,
            created_at TEXT
          )
        ''');

        // 2. Phrase Bank Table
        await db.execute('''
          CREATE TABLE phrase_bank (
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

        // 3. Word Dictionary Table
        await db.execute('''
          CREATE TABLE word_dictionary (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hindi_word TEXT NOT NULL,
            tribal_word TEXT NOT NULL,
            language TEXT NOT NULL,
            phonetic TEXT
          )
        ''');

        // 4. Flashcards Table
        await db.execute('''
          CREATE TABLE flashcards (
            id TEXT PRIMARY KEY,
            hindi_word TEXT NOT NULL,
            tribal_word TEXT NOT NULL,
            english_meaning TEXT,
            phonetic TEXT,
            icon_symbol TEXT,
            example_hindi TEXT,
            example_tribal TEXT
          )
        ''');

        // 5. Session Conversation Logs Table
        await db.execute('''
          CREATE TABLE session_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            original_text TEXT NOT NULL,
            translated_text TEXT NOT NULL,
            phonetic_text TEXT,
            language TEXT NOT NULL,
            source TEXT NOT NULL,
            latency_ms REAL NOT NULL,
            created_at TEXT
          )
        ''');

        // Seed initial data into SQLite Database
        await _seedDatabase(db);
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<void> _seedDatabase(Database db) async {
    try {
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
        });
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

  // --- AUTHENTICATION SQLITE OPERATIONS ---

  static Future<int> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await database;
    final passwordHash = _hashPassword(password);
    return await db.insert('users', {
      'name': name,
      'email': email.trim().toLowerCase(),
      'password_hash': passwordHash,
      'is_verified': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
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

  static Future<void> saveSessionLogToDb(TranslationResult log) async {
    final db = await database;

    final cleanInput = log.originalText.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleanInput.isEmpty) return;

    final inputKey = cleanInput.replaceAll(RegExp(r'[\s\.\।\?!\n,]'), '').toLowerCase();

    // Fetch existing session logs in chronological order
    final existingRows = await db.query('session_logs', orderBy: 'id ASC');

    if (existingRows.isNotEmpty) {
      final lastRow = existingRows.last;
      final lastId = lastRow['id'] as int;
      final lastOriginal = lastRow['original_text'].toString().trim().replaceAll(RegExp(r'\s+'), ' ');
      final lastKey = lastOriginal.replaceAll(RegExp(r'[\s\.\।\?!\n,]'), '').toLowerCase();

      // 1. Exact match with last entry -> Skip
      if (inputKey == lastKey) return;

      // 2. New input is a longer superset / expansion of the last entry -> Update last entry in DB!
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

      // 4. Check if new input is a substring of ANY previous entry in DB -> Skip
      for (final row in existingRows) {
        final rowOriginal = row['original_text'].toString().trim().replaceAll(RegExp(r'\s+'), ' ');
        final rowKey = rowOriginal.replaceAll(RegExp(r'[\s\.\।\?!\n,]'), '').toLowerCase();
        if (rowKey.contains(inputKey) || inputKey == rowKey) {
          return;
        }
      }
    }

    // 5. If it's a new independent sentence, insert as a new row
    await db.insert('session_logs', {
      'original_text': log.originalText,
      'translated_text': log.translatedText,
      'phonetic_text': log.phoneticText ?? '',
      'language': log.language.displayName,
      'source': log.source.label,
      'latency_ms': log.latencyMs,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<TranslationResult>> fetchSessionLogsFromDb() async {
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
