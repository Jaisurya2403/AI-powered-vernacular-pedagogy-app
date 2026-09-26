import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../engine/astar_translator.dart';
import '../engine/voice_biometrics_engine.dart';
import 'dataset_service.dart';
import 'speech_service.dart';
import 'flashcard_service.dart';
import 'db_helper.dart';
import 'email_service.dart';
import 'notes_generator_service.dart';
import '../translation/translator_manager.dart';

enum AppUiLanguage { english, hindi }

class AppState extends ChangeNotifier {
  final DatasetService datasetService = DatasetService();
  final SpeechService speechService = SpeechService();
  final FlashcardService flashcardService = FlashcardService();

  AppUiLanguage _uiLanguage = AppUiLanguage.english;
  TargetLanguage _targetLanguage = TargetLanguage.santhali;
  bool _isTeacherMode = true; // true = Hindi -> Tribal (Teacher), false = Tribal -> Hindi (Student Query)

  // Auth & User State stored persistently in SQLite
  UserModel? _currentUser;
  String? _pendingOtp;
  String? _pendingEmail;

  // Voice Biometrics Profile & Verification
  VoiceprintModel? _userVoiceprint;
  VoiceMatchResult? _lastVoiceMatch;

  // Teaching Sessions History
  List<TeachingSessionModel> _userTeachingHistory = [];

  List<TranslationResult> _sessionLogs = [];
  List<FlashcardItem> _flashcards = [];
  List<PhraseItem> _phraseBank = [];
  Map<String, String> _sqliteWordDictionary = {};

  String _currentLessonTopic = 'Mathematics & Primary Science (NIPUN Bharat)';

  // Subtitle real-time stream state
  String _currentInputText = '';
  String _livePartialHindiText = '';
  String _currentTranslatedText = '';
  String _currentPhoneticText = '';
  TranslationSource _currentSource = TranslationSource.phraseBank;
  double _currentLatencyMs = 0.0;
  bool _isTranslating = false;
  bool _isLoadingDb = true;

  // Getters
  AppUiLanguage get uiLanguage => _uiLanguage;
  TargetLanguage get targetLanguage => _targetLanguage;
  bool get isTeacherMode => _isTeacherMode;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get pendingEmail => _pendingEmail;

  VoiceprintModel? get userVoiceprint => _userVoiceprint;
  VoiceMatchResult? get lastVoiceMatch => _lastVoiceMatch;
  bool get hasEnrolledVoice => _userVoiceprint != null;
  List<TeachingSessionModel> get userTeachingHistory => _userTeachingHistory;

  List<TranslationResult> get sessionLogs => _sessionLogs;
  List<FlashcardItem> get flashcards => _flashcards;
  List<PhraseItem> get phraseBank => _phraseBank;
  String get currentLessonTopic => _currentLessonTopic;
  String get teacherName => _currentUser?.name ?? 'Teacher';
  String get teacherSchool => _currentUser?.school ?? 'Government Primary School';
  String get teacherDesignation => _currentUser?.designation ?? 'Primary Vernacular Teacher';
  String? get teacherEmail => _currentUser?.email;

  String get currentInputText => _currentInputText;
  String get livePartialHindiText => _livePartialHindiText;
  String get currentTranslatedText => _currentTranslatedText;
  String get currentPhoneticText => _currentPhoneticText;
  TranslationSource get currentSource => _currentSource;
  double get currentLatencyMs => _currentLatencyMs;
  bool get isTranslating => _isTranslating;
  bool get isLoadingDb => _isLoadingDb;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    _isLoadingDb = true;
    notifyListeners();

    try {
      await datasetService.initialize();
      await TranslatorManager().initialize();

      // Fetch dynamic data directly from SQLite Database
      _phraseBank = await DbHelper.fetchPhraseBankFromDb();
      _sqliteWordDictionary = await DbHelper.fetchWordDictionaryFromDb(_targetLanguage.code);
      _flashcards = await DbHelper.fetchFlashcardsFromDb();

      // Check for persistent active user session
      final activeEmail = await DbHelper.getActiveUserSession();
      if (activeEmail != null && activeEmail.isNotEmpty) {
        final userMap = await DbHelper.getUserByEmail(activeEmail);
        if (userMap != null) {
          _currentUser = UserModel.fromMap(userMap);
          debugPrint('[AppState] Auto-logged in persistent teacher: ${_currentUser!.name} (${_currentUser!.email})');

          // Load teacher's voiceprint profile & history
          await _loadUserData(_currentUser!.id);
        }
      }

      // If logged in, fetch persistent session logs
      if (_currentUser != null) {
        _sessionLogs = await DbHelper.fetchSessionLogsFromDb(userId: _currentUser?.id);
      } else {
        _sessionLogs = [];
      }

      debugPrint('[AppState] Dynamic data successfully loaded from SQLite Database.');
    } catch (e) {
      debugPrint('[AppState Init Error] $e');
    } finally {
      _isLoadingDb = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(int? userId) async {
    if (userId == null) return;
    try {
      _userVoiceprint = await DbHelper.getVoiceprintForUser(userId);
      _userTeachingHistory = await DbHelper.fetchTeachingSessionsForUser(userId);
      if (_userVoiceprint != null) {
        debugPrint('[AppState] Enrolled Voiceprint loaded for teacher ID: $userId');
      }
    } catch (e) {
      debugPrint('[AppState] Error loading user data: $e');
    }
  }

  void setUiLanguage(AppUiLanguage lang) {
    _uiLanguage = lang;
    notifyListeners();
  }

  Future<void> setTargetLanguage(TargetLanguage lang) async {
    _targetLanguage = lang;
    _sqliteWordDictionary = await DbHelper.fetchWordDictionaryFromDb(_targetLanguage.code);
    notifyListeners();
  }

  void toggleTeacherMode() {
    _isTeacherMode = !_isTeacherMode;
    notifyListeners();
  }

  void updateLessonTopic(String topic) {
    _currentLessonTopic = topic;
    notifyListeners();
  }

  // --- AUTHENTICATION ACTIONS WITH SQLITE & REAL GMAIL SMTP ---

  Future<String> signUp({
    required String name,
    required String email,
    required String password,
    String school = 'Government Primary School',
    String designation = 'Primary Vernacular Teacher',
  }) async {
    final existing = await DbHelper.getUserByEmail(email);
    if (existing != null && (existing['is_verified'] as int? ?? 0) == 1) {
      throw Exception('An account with this email already exists.');
    }

    if (existing == null) {
      await DbHelper.registerUser(
        name: name,
        email: email,
        password: password,
        school: school,
        designation: designation,
      );
    }

    final otp = EmailService.generateOtp();
    _pendingOtp = otp;
    _pendingEmail = email.trim().toLowerCase();

    final sent = await EmailService.sendOtpEmail(
      recipientEmail: email,
      recipientName: name,
      otpCode: otp,
    );

    if (!sent) {
      throw Exception('Failed to send OTP verification email. Please check internet connection.');
    }

    return otp;
  }

  Future<bool> verifyOtp(String inputOtp) async {
    if (_pendingOtp == null || _pendingEmail == null) return false;

    if (inputOtp.trim() == _pendingOtp!.trim()) {
      await DbHelper.markUserVerified(_pendingEmail!);
      final userMap = await DbHelper.getUserByEmail(_pendingEmail!);
      if (userMap != null) {
        _currentUser = UserModel.fromMap(userMap);
        await DbHelper.setActiveUserSession(_currentUser!.email);
        await _loadUserData(_currentUser!.id);
        _sessionLogs = await DbHelper.fetchSessionLogsFromDb(userId: _currentUser?.id);
      }
      _pendingOtp = null;
      _pendingEmail = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final userMap = await DbHelper.loginUser(email: email, password: password);
    if (userMap != null) {
      _currentUser = UserModel.fromMap(userMap);
      await DbHelper.setActiveUserSession(email);
      await _loadUserData(_currentUser!.id);
      _sessionLogs = await DbHelper.fetchSessionLogsFromDb(userId: _currentUser?.id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<String> sendForgotPasswordOtp(String email) async {
    final userMap = await DbHelper.getUserByEmail(email);
    if (userMap == null) {
      throw Exception('No account found with this email address.');
    }

    final otp = EmailService.generateOtp();
    _pendingOtp = otp;
    _pendingEmail = email.trim().toLowerCase();

    final sent = await EmailService.sendPasswordResetEmail(
      recipientEmail: email,
      resetCode: otp,
    );

    if (!sent) {
      throw Exception('Failed to send password reset email.');
    }

    return otp;
  }

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
    required String inputOtp,
  }) async {
    if (_pendingOtp == null || inputOtp.trim() != _pendingOtp!.trim()) {
      throw Exception('Invalid or expired OTP code.');
    }

    final updated = await DbHelper.updatePassword(email: email, newPassword: newPassword);
    if (updated) {
      _pendingOtp = null;
      _pendingEmail = null;
      notifyListeners();
      return true;
    }
    return false;
  }


  Future<void> signOut() async {
    await DbHelper.clearActiveUserSession();
    _currentUser = null;
    _userVoiceprint = null;
    _lastVoiceMatch = null;
    _userTeachingHistory = [];
    _sessionLogs.clear();
    _currentInputText = '';
    _currentTranslatedText = '';
    _currentPhoneticText = '';
    _livePartialHindiText = '';
    notifyListeners();
  }

  // --- PROFILE MANAGEMENT ---

  Future<bool> updateUserProfile({
    required String name,
    required String school,
    String? designation,
  }) async {
    if (_currentUser == null || _currentUser!.id == null) return false;

    final success = await DbHelper.updateUserProfile(
      userId: _currentUser!.id!,
      name: name,
      school: school,
      designation: designation,
    );

    if (success) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        school: school,
        designation: designation,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- VOICE BIOMETRICS ASSISTANT (75% Threshold Matching) ---

  Future<void> enrollTeacherVoice(String referencePrompt, {List<double>? acousticSamples}) async {
    if (_currentUser == null || _currentUser!.id == null) {
      throw Exception('Please sign in to save your voice profile.');
    }

    final voiceprint = VoiceBiometricsEngine.createVoiceprint(
      userId: _currentUser!.id!,
      referenceText: referencePrompt,
      acousticSamples: acousticSamples,
    );

    await DbHelper.saveVoiceprint(voiceprint);
    _userVoiceprint = voiceprint;
    _currentUser = _currentUser!.copyWith(hasVoiceprint: true);
    notifyListeners();
  }

  Future<void> enrollTeacherCompositeVoice(
    List<String> sentences, {
    List<SpeechDeliveryMetrics>? deliveryMetrics,
    List<List<double>>? acousticSamplesList, // legacy, unused
  }) async {
    if (_currentUser == null || _currentUser!.id == null) {
      throw Exception('Please sign in to save your voice profile.');
    }

    final voiceprint = VoiceBiometricsEngine.createCompositeVoiceprint(
      userId: _currentUser!.id!,
      sentences: sentences,
      deliveryMetrics: deliveryMetrics ?? [],
    );

    await DbHelper.saveVoiceprint(voiceprint);
    _userVoiceprint = voiceprint;
    _currentUser = _currentUser!.copyWith(hasVoiceprint: true);
    debugPrint('[AppState] Composite voiceprint saved: ${voiceprint.sampleCount} samples, '
        'embedding length: ${(jsonDecode(voiceprint.embedding) as List).length}D');
    notifyListeners();
  }

  Future<void> deleteTeacherVoice() async {
    if (_currentUser == null || _currentUser!.id == null) return;
    await DbHelper.deleteVoiceprint(_currentUser!.id!);
    _userVoiceprint = null;
    _lastVoiceMatch = null;
    _currentUser = _currentUser!.copyWith(hasVoiceprint: false);
    notifyListeners();
  }

  VoiceMatchResult testVoiceMatch(String testSpeech, {SpeechDeliveryMetrics? deliveryMetrics}) {
    final result = VoiceBiometricsEngine.verifyVoice(
      spokenText: testSpeech,
      enrolledVoiceprint: _userVoiceprint,
      deliveryMetrics: deliveryMetrics,
      teacherName: teacherName,
    );
    _lastVoiceMatch = result;
    notifyListeners();
    return result;
  }

  // --- TEACHING SESSION HISTORY MANAGEMENT ---

  Future<void> saveCurrentTeachingSession({String? docxPath, String? txtPath}) async {
    if (_sessionLogs.isEmpty) return;

    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final session = TeachingSessionModel(
      userId: _currentUser?.id,
      topic: _currentLessonTopic,
      teacherName: teacherName,
      targetLanguage: _targetLanguage.displayName,
      dateStr: dateStr,
      timeStr: timeStr,
      totalSentences: _sessionLogs.length,
      notesFilePath: txtPath ?? NotesGeneratorService.activeLiveTxtPath,
      docxFilePath: docxPath,
    );

    await DbHelper.saveTeachingSession(session);
    _userTeachingHistory = await DbHelper.fetchTeachingSessionsForUser(_currentUser?.id);
    notifyListeners();
  }

  Future<void> deleteTeachingSession(int sessionId) async {
    await DbHelper.deleteTeachingSession(sessionId);
    _userTeachingHistory = await DbHelper.fetchTeachingSessionsForUser(_currentUser?.id);
    notifyListeners();
  }

  // --- REAL-TIME TRANSLATION WITH VOICE BIOMETRICS MATCHING ---

  void updateLivePartialText(String text) {
    _livePartialHindiText = text;
    notifyListeners();
  }

  Future<TranslationResult?> processTranslation(
    String inputText, {
    SpeechDeliveryMetrics? deliveryMetrics,
  }) async {
    final cleanInput = inputText.trim();
    if (cleanInput.isEmpty) return null;

    // 1. Voice Biometrics Verification (75% match threshold if teacher enrolled voice)
    if (_isTeacherMode && _userVoiceprint != null) {
      final matchResult = VoiceBiometricsEngine.verifyVoice(
        spokenText: cleanInput,
        enrolledVoiceprint: _userVoiceprint,
        deliveryMetrics: deliveryMetrics,
        teacherName: teacherName,
      );
      _lastVoiceMatch = matchResult;

      if (!matchResult.isMatched) {
        final scorePct = (matchResult.similarityScore * 100).toStringAsFixed(0);
        debugPrint('[VoiceBiometrics Filter] Background voice ignored (< 75% match): $cleanInput (Score: $scorePct%)');
        _livePartialHindiText = '⚠️ Background voice ignored ($scorePct% match < 75%)';
        notifyListeners();
        return null; // Suppress background voice from interrupting classroom
      } else {
        debugPrint('[VoiceBiometrics Verified] Teacher voice confirmed: ${(matchResult.similarityScore * 100).toStringAsFixed(1)}%');
      }
    }

    _isTranslating = true;
    _currentInputText = cleanInput;
    _livePartialHindiText = '';
    notifyListeners();

    TranslationResult result;

    if (_isTeacherMode) {
      // Step 2: High-Performance 3-Tier A* Translation Engine (Hindi -> Santhali Ol Chiki)
      final step2Res = TranslatorManager().translator.translate(cleanInput);
      final translatedSanthali = step2Res.santaliText.isNotEmpty
          ? step2Res.santaliText
          : AStarTranslatorEngine.translate(
              inputText: cleanInput,
              targetLanguage: _targetLanguage,
              wordDictionary: _sqliteWordDictionary.isNotEmpty
                  ? _sqliteWordDictionary
                  : datasetService.getDictionary(_targetLanguage),
              parallelCorpus: datasetService.getParallelCorpus(_targetLanguage),
              phraseBank: _phraseBank.isNotEmpty ? _phraseBank : datasetService.phraseBank,
            ).translatedText;

      result = TranslationResult(
        originalText: cleanInput,
        translatedText: translatedSanthali,
        language: _targetLanguage,
        source: step2Res.method == 'exact'
            ? TranslationSource.phraseBank
            : TranslationSource.astarSearch,
        latencyMs: step2Res.latencyMs,
      );

      // Synthesize Tribal Audio at Pronounce Point
      await speechService.speakTribalText(result.translatedText, _targetLanguage);
    } else {
      // Student speaks Tribal (Santali) -> Reverse Translation to Hindi
      final step2Res = TranslatorManager().translator.translateReverse(cleanInput);
      final translatedHindi = step2Res.santaliText.isNotEmpty ? step2Res.santaliText : cleanInput;

      result = TranslationResult(
        originalText: cleanInput,
        translatedText: translatedHindi,
        language: _targetLanguage,
        source: step2Res.method == 'exact'
            ? TranslationSource.phraseBank
            : TranslationSource.astarSearch,
        latencyMs: step2Res.latencyMs,
      );

      await speechService.speakHindiText(result.translatedText);
    }

    _currentTranslatedText = result.translatedText;
    _currentPhoneticText = result.phoneticText ?? '';
    _currentSource = result.source;
    _currentLatencyMs = result.latencyMs;
    _isTranslating = false;

    // Save session log into SQLite Database (persistently linked to user)
    await DbHelper.saveSessionLogToDb(result, userId: _currentUser?.id);
    _sessionLogs = await DbHelper.fetchSessionLogsFromDb(userId: _currentUser?.id);

    // Auto-append live speech into session notes file (.txt & .docx)
    try {
      await NotesGeneratorService.appendSpeechToLiveNotesFile(
        hindiText: cleanInput,
        translatedText: result.translatedText,
        targetLanguage: _targetLanguage,
        lessonTopic: _currentLessonTopic,
        teacherName: teacherName,
        teacherSchool: teacherSchool,
        teacherDesignation: teacherDesignation,
      );
    } catch (e) {
      debugPrint('[AppState] Auto-append live notes error: $e');
    }

    notifyListeners();
    return result;
  }

  Future<void> clearSessionNotes() async {
    await DbHelper.clearSessionLogsFromDb();
    _sessionLogs.clear();
    _currentInputText = '';
    _currentTranslatedText = '';
    _currentPhoneticText = '';
    _livePartialHindiText = '';
    await NotesGeneratorService.clearLiveNotesFile();
    notifyListeners();
  }

  void clearSessionLogs() {
    clearSessionNotes();
  }
}
