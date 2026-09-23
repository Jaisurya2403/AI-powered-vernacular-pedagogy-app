import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/app_models.dart';
import '../engine/hindi_text_normalizer.dart';
import '../engine/ol_chiki_transliteration.dart';
import 'web_speech_helper.dart';

enum AudioOutputDevice {
  bluetoothSpeaker,
  deviceSpeaker,
}

class SpeechService extends ChangeNotifier {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _speechInitialized = false;
  AudioOutputDevice _outputDevice = AudioOutputDevice.bluetoothSpeaker;

  Timer? _restartLoopTimer;
  Timer? _watchdogTimer;
  Timer? _silenceFlushTimer;
  Function(String text)? _activeResultCallback;
  Function(String partial)? _activePartialCallback;

  final Set<String> _submittedSentenceHashes = {};
  final List<String> _submittedSentenceList = [];
  String _uncommittedBuffer = '';
  String _lastSubmittedChunk = '';

  // Acoustic Echo Rejection & Self-Voice Suppression Filter
  static final Set<String> _systemSpokenTtsHashes = {};
  static final List<String> _systemSpokenTtsPhrases = [];
  static DateTime _lastTtsFinishedTime = DateTime.fromMillisecondsSinceEpoch(0);

  static void registerSystemTtsOutput(String text, [String? phoneticText]) {
    final clean1 = HindiTextNormalizer.normalize(text).replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (clean1.isNotEmpty) {
      _systemSpokenTtsHashes.add(clean1);
      _systemSpokenTtsPhrases.add(clean1);
    }
    if (phoneticText != null && phoneticText.isNotEmpty) {
      final clean2 = HindiTextNormalizer.normalize(phoneticText).replaceAll(RegExp(r'\s+'), '').toLowerCase();
      if (clean2.isNotEmpty) {
        _systemSpokenTtsHashes.add(clean2);
        _systemSpokenTtsPhrases.add(clean2);
      }
    }

    if (_systemSpokenTtsPhrases.length > 50) {
      _systemSpokenTtsPhrases.removeAt(0);
    }
  }

  bool _isSystemVoiceEcho(String candidateText) {
    if (candidateText.trim().isEmpty) return false;

    // 1. Check if TTS is currently active or finished within 400ms decay window
    final isWithinTtsWindow = _isSpeaking || DateTime.now().difference(_lastTtsFinishedTime).inMilliseconds < 400;

    final key = HindiTextNormalizer.normalize(candidateText).replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (key.isEmpty) return false;

    // 2. Hash match against system spoken TTS phrases
    if (_systemSpokenTtsHashes.contains(key)) return true;

    // 3. Substring / Overlap match against recent TTS output
    for (final phrase in _systemSpokenTtsPhrases) {
      if (phrase.contains(key) || key.contains(phrase)) {
        return true;
      }
    }

    // 4. Check prefix similarity during active TTS playback
    if (isWithinTtsWindow && _systemSpokenTtsPhrases.isNotEmpty) {
      final lastTts = _systemSpokenTtsPhrases.last;
      if (lastTts.length >= 2 && key.length >= 2) {
        if (key.startsWith(lastTts.substring(0, 2)) || lastTts.startsWith(key.substring(0, 2))) {
          return true;
        }
      }
    }

    return false;
  }

  double _speechRate = 0.38; // Calm, steady rate for young primary students

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isHardwareMicListening => _speechToText.isListening;
  Future<bool> get hasPermission => _speechToText.hasPermission;
  bool get speechInitialized => _speechInitialized;
  AudioOutputDevice get outputDevice => _outputDevice;
  double get speechRate => _speechRate;
  String get lastSubmittedChunk => _lastSubmittedChunk;

  SpeechService() {
    _initTts();
    initializeSpeech();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    try {
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (_) {}
    notifyListeners();
  }

  bool _isReEngaging = false;

  Future<bool> initializeSpeech() async {
    if (_speechInitialized) return true;
    try {
      _speechInitialized = await _speechToText.initialize(
        onError: (val) {
          debugPrint("[STT Error] ${val.errorMsg}");
          final errStr = val.errorMsg.toLowerCase();
          if (errStr.contains('already started') || errStr.contains('invalidstate')) {
            return;
          }
          if (_isListening) {
            _scheduleImmediateReEngage();
          }
        },
        onStatus: (status) {
          debugPrint("[STT Status] $status");
          notifyListeners();
          if (_isListening && (status == 'done' || status == 'notListening')) {
            _scheduleImmediateReEngage();
          }
        },
      );
      notifyListeners();
      return _speechInitialized;
    } catch (e) {
      _speechInitialized = false;
      return false;
    }
  }

  /// Strict 1-Second Heartbeat Watchdog Timer
  void _startWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isListening && _speechInitialized && !_speechToText.isListening && !_isReEngaging && _activeResultCallback != null) {
        debugPrint('[SpeechService 1s Watchdog] Microphone hardware is OFF. Re-engaging mic stream immediately...');
        _forceReEngageMic();
      }
    });
  }

  void _stopWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  /// High-Performance Asynchronous Mic Re-engager with 60ms Audio HAL Flush
  Future<void> _forceReEngageMic([String localeId = 'hi_IN']) async {
    if (!_isListening || _activeResultCallback == null || _isReEngaging) return;
    if (_speechToText.isListening) return;

    _isReEngaging = true;
    try {
      await _speechToText.cancel();
      await Future.delayed(const Duration(milliseconds: 60));

      if (!_isListening) {
        _isReEngaging = false;
        return;
      }

      await _speechToText.listen(
        onResult: (result) {
          final recognized = result.recognizedWords.trim();
          if (recognized.isNotEmpty) {
            final normalizedPartial = HindiTextNormalizer.normalize(recognized);
            _activePartialCallback?.call(normalizedPartial);
            _processSpeechStream(recognized);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: localeId,
          listenFor: const Duration(hours: 4),
          pauseFor: const Duration(seconds: 30),
          cancelOnError: false,
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint("[STT Force Re-engage Error] $e");
    } finally {
      _isReEngaging = false;
      notifyListeners();
    }
  }

  /// Fast Recovery Scheduler for STT Interruptions
  void _scheduleImmediateReEngage() {
    if (!_isListening || _activeResultCallback == null) return;

    _restartLoopTimer?.cancel();
    _restartLoopTimer = Timer(const Duration(milliseconds: 80), () {
      if (_isListening && !_speechToText.isListening && !_isReEngaging) {
        _forceReEngageMic();
      }
    });
  }

  /// Public trigger to re-engage mic when app resumes from background or screen wake
  void reEngageMicIfEnabled() {
    if (_isListening && !_speechToText.isListening) {
      _forceReEngageMic();
    }
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        notifyListeners();
      });
    } catch (_) {}
  }

  void toggleAudioOutput() {
    if (_outputDevice == AudioOutputDevice.bluetoothSpeaker) {
      _outputDevice = AudioOutputDevice.deviceSpeaker;
    } else {
      _outputDevice = AudioOutputDevice.bluetoothSpeaker;
    }
    notifyListeners();
  }

  void toggleAudioOutputDevice() => toggleAudioOutput();

  Future<void> startContinuousTeacherSpeechStream({
    required Function(String text) onChunkRecognized,
    Function(String partial)? onPartialRecognized,
    String localeId = 'hi_IN',
  }) =>
      startListening(
        onResultText: onChunkRecognized,
        onPartialText: onPartialRecognized,
        localeId: localeId,
      );

  Future<void> stopContinuousListening() => stopListening();

  /// Starts continuous speech recognition with natural sentence boundary detection & deduplication
  Future<void> startListening({
    required Function(String text) onResultText,
    Function(String partial)? onPartialText,
    String localeId = 'hi_IN',
  }) async {
    _isListening = true;
    _lastSubmittedChunk = '';
    _submittedSentenceHashes.clear();
    _submittedSentenceList.clear();
    _uncommittedBuffer = '';
    _activeResultCallback = onResultText;
    _activePartialCallback = onPartialText;
    notifyListeners();

    await initializeSpeech();
    _startWatchdogTimer();

    if (_speechInitialized && !_speechToText.isListening) {
      _forceReEngageMic(localeId);
    }
  }

  /// Synchronizes recognized chunk with local Vosk STT Microservice (Port 8086) if active
  Future<void> _syncChunkToVoskMicroservice(String text) async {
    try {
      final uri = Uri.parse('http://127.0.0.1:8086/api/vosk/push-chunk');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: '{"chunk": "${text.replaceAll('"', '\\"')}"}',
          )
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {
      // Safe fallback when running on device or offline
    }
  }

  /// Processes continuous STT stream into clean, non-duplicated sentences & micro-gap phrases
  void _processSpeechStream(String rawRecognizedText) {
    if (_activeResultCallback == null || !_isListening) return;

    final normalized = HindiTextNormalizer.normalize(rawRecognizedText).trim();
    if (normalized.isEmpty) return;

    _silenceFlushTimer?.cancel();

    // Split stream into clauses using boundary delimiters (। . ? ! , ; - \n)
    final clauseDelimiterRegex = RegExp(r'(?<=[।\.\?!\n,;\-])');
    final rawParts = normalized.split(clauseDelimiterRegex);

    String pendingRemainder = '';

    for (int i = 0; i < rawParts.length; i++) {
      final part = rawParts[i].trim();
      if (part.isEmpty) continue;

      final isCompleteClause = RegExp(r'[।\.\?!\n,;\-]$').hasMatch(part);

      if (isCompleteClause || i < rawParts.length - 1) {
        _emitSentenceIfNew(part);
      } else {
        pendingRemainder = part;
      }
    }

    _uncommittedBuffer = pendingRemainder;

    // Real-Time 450ms Gap Detection Timer:
    // When the teacher pauses for 450ms, flush the pending phrase immediately as a segment boundary
    if (_uncommittedBuffer.isNotEmpty) {
      _silenceFlushTimer = Timer(const Duration(milliseconds: 450), () {
        if (_isListening && _uncommittedBuffer.isNotEmpty) {
          _emitSentenceIfNew(_uncommittedBuffer);
          _uncommittedBuffer = '';
        }
      });
    }
  }

  void _emitSentenceIfNew(String sentence) {
    final cleaned = HindiTextNormalizer.normalize(sentence).trim();
    if (cleaned.isEmpty) return;

    String deltaPhrase = cleaned;

    // Strip out previously emitted phrase prefixes to isolate new spoken delta
    for (final prev in _submittedSentenceList) {
      if (prev.isNotEmpty && deltaPhrase.startsWith(prev)) {
        deltaPhrase = deltaPhrase.substring(prev.length).trim();
      }
    }

    final cleanedDelta = HindiTextNormalizer.normalize(deltaPhrase).trim();
    if (cleanedDelta.isEmpty) return;

    // Acoustic Echo Suppression: Ignore system's own speaker voice output
    if (_isSystemVoiceEcho(cleanedDelta)) {
      debugPrint('[Acoustic Echo Rejection] Suppressed system TTS self-voice echo: "$cleanedDelta"');
      return;
    }

    final dedupeKey = cleanedDelta.replaceAll(RegExp(r'\s+'), '').toLowerCase();

    if (!_submittedSentenceHashes.contains(dedupeKey)) {
      _submittedSentenceHashes.add(dedupeKey);
      _submittedSentenceList.add(cleaned);
      _lastSubmittedChunk = cleanedDelta;
      _activeResultCallback?.call(cleanedDelta);
      _syncChunkToVoskMicroservice(cleanedDelta);
      debugPrint('[SpeechService Live Gap Emitted Chunk] $cleanedDelta');
    } else {
      debugPrint('[SpeechService Live Gap Duplicate Skipped] $cleanedDelta');
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    _stopWatchdogTimer();
    _silenceFlushTimer?.cancel();
    _restartLoopTimer?.cancel();

    if (_uncommittedBuffer.isNotEmpty) {
      _emitSentenceIfNew(_uncommittedBuffer);
      _uncommittedBuffer = '';
    }

    _activeResultCallback = null;
    _activePartialCallback = null;
    notifyListeners();

    if (_speechInitialized) {
      try {
        await _speechToText.stop();
      } catch (_) {}
    }
  }

  void _onTtsFinished() {
    _isSpeaking = false;
    _lastTtsFinishedTime = DateTime.now();
    notifyListeners();
  }

  Future<void> speakTribalText(String text, TargetLanguage language) async {
    if (text.trim().isEmpty) return;
    _isSpeaking = true;
    notifyListeners();

    final phoneticSpeechText = OlChikiTransliteration.toDevanagari(text);
    registerSystemTtsOutput(text, phoneticSpeechText);

    // 1. Web Environment: Use Native Chrome Web Speech Synthesis API
    if (kIsWeb) {
      try {
        WebSpeechHelper.speakOnWeb(phoneticSpeechText);
      } catch (e) {
        debugPrint('[Web Speech Error] $e');
      } finally {
        _onTtsFinished();
      }
      return;
    }

    // 2. Mobile & Desktop Environments: Try Meta MMS Santali Microservice (Port 8088)
    final hostIp = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final microserviceUri = Uri.parse('http://$hostIp:8088/api/mms-tts/speak');

    try {
      final res = await http
          .post(
            microserviceUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(milliseconds: 1000));

      if (res.statusCode == 200) {
        _onTtsFinished();
        return;
      }
    } catch (_) {
      // Offline fallback to native FlutterTTS
    }

    // 3. Native FlutterTTS Fallback
    try {
      await _flutterTts.setVolume(1.0); // Maximum 100% volume gain
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setLanguage("hi-IN");
      await _flutterTts.speak(phoneticSpeechText);
    } catch (e) {
      debugPrint("[TTS Error] $e");
    } finally {
      _onTtsFinished();
    }
  }

  Future<void> speakHindiText(String text) async {
    if (text.trim().isEmpty) return;
    _isSpeaking = true;
    notifyListeners();

    registerSystemTtsOutput(text);

    if (kIsWeb) {
      try {
        WebSpeechHelper.speakOnWeb(text);
      } catch (e) {
        debugPrint('[Web Speech Error] $e');
      } finally {
        _onTtsFinished();
      }
      return;
    }

    try {
      await _flutterTts.setVolume(1.0); // Maximum 100% volume gain
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setLanguage("hi-IN");
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("[TTS Error] $e");
    } finally {
      _onTtsFinished();
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopWatchdogTimer();
    _restartLoopTimer?.cancel();
    _silenceFlushTimer?.cancel();
    super.dispose();
  }
}

