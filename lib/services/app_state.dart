import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../engine/astar_translator.dart';
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

  // Auth & User State stored in SQLite
  UserModel? _currentUser;
  String? _pendingOtp;
  String? _pendingEmail;

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

  List<TranslationResult> get sessionLogs => _sessionLogs;
  List<FlashcardItem> get flashcards => _flashcards;
  List<PhraseItem> get phraseBank => _phraseBank;
  String get currentLessonTopic => _currentLessonTopic;
  String get teacherName => _currentUser?.name ?? 'Teacher';

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
      _sessionLogs = await DbHelper.fetchSessionLogsFromDb();

      debugPrint('[AppState] Dynamic data successfully loaded from SQLite Database.');
    } catch (e) {
      debugPrint('[AppState Init Error] $e');
    } finally {
      _isLoadingDb = false;
      notifyListeners();
    }
  }

  void setUiLanguage(AppUiLanguage lang) {
    _uiLanguage = lang;
    notifyListeners();
  }

  Future<void> setTargetLanguage(TargetLanguage lang) async {
    _targetLanguage = lang;
    // Reload dictionary for chosen target language from SQLite
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

  /// Register user, store in SQLite, send real OTP email via Gmail SMTP
  Future<String> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final existing = await DbHelper.getUserByEmail(email);
    if (existing != null && (existing['is_verified'] as int? ?? 0) == 1) {
      throw Exception('An account with this email already exists.');
    }

    if (existing == null) {
      await DbHelper.registerUser(name: name, email: email, password: password);
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

  /// Verify entered OTP pin, mark user as verified in SQLite, log user in
  Future<bool> verifyOtp(String inputOtp) async {
    if (_pendingOtp == null || _pendingEmail == null) return false;

    if (inputOtp.trim() == _pendingOtp!.trim()) {
      await DbHelper.markUserVerified(_pendingEmail!);
      final userMap = await DbHelper.getUserByEmail(_pendingEmail!);
      if (userMap != null) {
        _currentUser = UserModel.fromMap(userMap);
      }
      _pendingOtp = null;
      _pendingEmail = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Sign In with Email and Password from SQLite database
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final userMap = await DbHelper.loginUser(email: email, password: password);
    if (userMap != null) {
      _currentUser = UserModel.fromMap(userMap);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Send Forgot Password OTP to user email via Gmail SMTP
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

  /// Reset Password in SQLite DB
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

  void signOut() {
    _currentUser = null;
    notifyListeners();
  }

  void updateLivePartialText(String text) {
    _livePartialHindiText = text;
    notifyListeners();
  }

  /// Main Real-Time Translation Execution Pipeline
  Future<TranslationResult> processTranslation(String inputText) async {
    _isTranslating = true;
    _currentInputText = inputText;
    _livePartialHindiText = '';
    notifyListeners();

    TranslationResult result;

    if (_isTeacherMode) {
      // Step 2: High-Performance 3-Tier A* Translation Engine (Hindi -> Santhali Ol Chiki)
      final step2Res = TranslatorManager().translator.translate(inputText);
      final translatedSanthali = step2Res.santaliText.isNotEmpty
          ? step2Res.santaliText
          : AStarTranslatorEngine.translate(
              inputText: inputText,
              targetLanguage: _targetLanguage,
              wordDictionary: _sqliteWordDictionary.isNotEmpty
                  ? _sqliteWordDictionary
                  : datasetService.getDictionary(_targetLanguage),
              parallelCorpus: datasetService.getParallelCorpus(_targetLanguage),
              phraseBank: _phraseBank.isNotEmpty ? _phraseBank : datasetService.phraseBank,
            ).translatedText;

      result = TranslationResult(
        originalText: inputText,
        translatedText: translatedSanthali,
        language: _targetLanguage,
        source: step2Res.method == 'exact'
            ? TranslationSource.phraseBank
            : TranslationSource.astarSearch,
        latencyMs: step2Res.latencyMs,
      );

      // Synthesize Tribal Audio immediately upon translation to Santali
      await speechService.speakTribalText(result.translatedText, _targetLanguage);
    } else {
      // Student speaks Tribal language -> Output Hindi for teacher
      result = TranslationResult(
        originalText: inputText,
        translatedText: 'शिक्षक ध्यान दें: विद्यार्थी प्रश्न: "$inputText"',
        language: _targetLanguage,
        source: TranslationSource.astarSearch,
        latencyMs: 18.2,
      );

      await speechService.speakHindiText(result.translatedText);
    }

    _currentTranslatedText = result.translatedText;
    _currentPhoneticText = result.phoneticText ?? '';
    _currentSource = result.source;
    _currentLatencyMs = result.latencyMs;
    _isTranslating = false;

    // Save session log into SQLite Database!
    await DbHelper.saveSessionLogToDb(result);
    _sessionLogs = await DbHelper.fetchSessionLogsFromDb();

    // Auto-append live speech into real-time session notes file (.txt & .docx)
    try {
      await NotesGeneratorService.appendSpeechToLiveNotesFile(
        hindiText: inputText,
        translatedText: result.translatedText,
        targetLanguage: _targetLanguage,
        lessonTopic: _currentLessonTopic,
        teacherName: teacherName,
      );
    } catch (e) {
      debugPrint('[AppState] Auto-append live notes error: $e');
    }

    notifyListeners();
    return result;
  }

  /// Clears session notes / speech logs alone without touching user auth or database settings
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
