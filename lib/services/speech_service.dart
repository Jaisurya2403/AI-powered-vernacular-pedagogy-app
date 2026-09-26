import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/app_models.dart';
import '../engine/hindi_text_normalizer.dart';
import '../engine/ol_chiki_transliteration.dart';
import '../engine/speech_segmenter.dart';
import '../engine/voice_biometrics_engine.dart';
import 'web_speech_helper.dart';
import 'web_stt_engine.dart'; // Chrome-specific continuous STT engine

enum AudioOutputDevice {
  bluetoothSpeaker,
  deviceSpeaker,
}

class SpeechService extends ChangeNotifier {
  // ── Used on native (Android/iOS/Desktop) only ────────────────────────────────
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _isReEngaging = false;
  bool _pendingListenStart = false;
  int _consecutiveAborts = 0;
  Timer? _reEngageTimer;
  Timer? _watchdogTimer;
  static const int _baseRetryMs = 600;
  static const int _maxRetryMs  = 5000;

  // ── Shared state ─────────────────────────────────────────────────────────────
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening  = false;
  bool _isSpeaking   = false;
  AudioOutputDevice _outputDevice = AudioOutputDevice.bluetoothSpeaker;

  Timer? _silenceFlushTimer;
  Timer? _echoTailTimer;
  Timer? _voskPollTimer;
  int    _lastVoskIndex = 0;

  Function(String text, SpeechDeliveryMetrics? metrics)? _activeResultCallback;
  Function(String partial)? _activePartialCallback;

  // ── Delivery Timing Metrics Trackers ─────────────────────────────────────────
  DateTime? _chunkStartTime;
  DateTime? _firstPartialTime;
  int       _partialUpdateCount = 0;
  DateTime? _lastEmittedSentenceEndTime;

  final Set<String>  _submittedSentenceHashes = {};
  final List<String> _submittedSentenceList    = [];
  final Set<String>  _recentlySpokenTtsHashes  = {};
  bool   _isEchoDampening  = false;
  String _uncommittedBuffer = '';
  String _lastSubmittedChunk = '';
  String? _localeId;

  double _speechRate = 0.38;

  bool   get isListening       => _isListening;
  bool   get isSpeaking        => _isSpeaking;
  bool   get isAnySpeechPlaying =>
      _isSpeaking || WebSpeechHelper.isWebSpeechPlaying || _isEchoDampening;
  bool   get isHardwareMicListening =>
      (kIsWeb ? webSttIsListening : _speechToText.isListening) ||
      _voskPollTimer != null;
  Future<bool> get hasPermission => _speechToText.hasPermission;
  bool   get speechInitialized => kIsWeb ? webSttIsSupported : _speechInitialized;
  AudioOutputDevice get outputDevice => _outputDevice;
  double get speechRate        => _speechRate;
  String get lastSubmittedChunk => _lastSubmittedChunk;

  bool get _nativeMicBusy => _isReEngaging || _pendingListenStart;

  SpeechService() {
    _initTts();
    if (!kIsWeb) initializeSpeech();
  }

  String get _hostIp => '127.0.0.1';

  // ── Vosk Microservice Poller ─────────────────────────────────────────────────
  void _startVoskPoller() {
    _voskPollTimer?.cancel();
    _voskPollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!_isListening || _activeResultCallback == null) return;
      try {
        final uri = Uri.parse('http://$_hostIp:8086/api/vosk/poll-new?since=$_lastVoskIndex');
        final res = await http.get(uri).timeout(const Duration(milliseconds: 150));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final List newSentences = data['new_sentences'] ?? [];
          final int  nextIdx      = data['next_index'] ?? _lastVoskIndex;
          final String partial    = data['partial'] ?? '';
          _lastVoskIndex = nextIdx;
          if (partial.isNotEmpty) {
            _activePartialCallback?.call(HindiTextNormalizer.normalize(partial));
          }
          for (final s in newSentences) {
            final text = s.toString().trim();
            if (text.isNotEmpty) _processSpeechStream(text);
          }
        }
      } catch (_) {}
    });
  }

  void _stopVoskPoller() {
    _voskPollTimer?.cancel();
    _voskPollTimer = null;
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    try { await _flutterTts.setSpeechRate(_speechRate); } catch (_) {}
    notifyListeners();
  }

  // ── Echo / TTS suppression ───────────────────────────────────────────────────
  void registerSpokenTtsHash(String text) {
    final normalized = HindiTextNormalizer.normalize(text);
    if (normalized.isEmpty) return;
    final devanagari = OlChikiTransliteration.toDevanagari(text);
    final normDeva   = HindiTextNormalizer.normalize(devanagari);
    for (final str in [normalized, normDeva]) {
      if (str.isEmpty) continue;
      _recentlySpokenTtsHashes.add(str.replaceAll(RegExp(r'\s+'), '').toLowerCase());
      final words = str.split(RegExp(r'\s+'));
      for (int i = 0; i < words.length; i++) {
        final w = words[i].trim().toLowerCase();
        if (w.isNotEmpty) _recentlySpokenTtsHashes.add(w);
        if (i < words.length - 1) {
          _recentlySpokenTtsHashes.add((words[i] + words[i + 1]).toLowerCase());
        }
      }
    }
  }

  void startEchoDampeningTail() {
    _isEchoDampening = true;
    _echoTailTimer?.cancel();
    _echoTailTimer = Timer(const Duration(milliseconds: 1200), () {
      _isEchoDampening = false;
    });
  }

  Future<void> _notifyVoskMicMuteState(bool mute) async {
    try {
      await http.post(
        Uri.parse('http://$_hostIp:8086/api/vosk/mic/${mute ? "mute" : "unmute"}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      ).timeout(const Duration(milliseconds: 300));
    } catch (_) {}
  }

  // ── TTS speak methods ────────────────────────────────────────────────────────
  Future<void> speakTribalText(String text, TargetLanguage targetLang) async {
    if (text.trim().isEmpty) return;
    _isSpeaking = true;
    notifyListeners();
    registerSpokenTtsHash(text);
    final phoneticText = OlChikiTransliteration.toDevanagari(text);
    registerSpokenTtsHash(phoneticText);
    await _notifyVoskMicMuteState(true);
    try {
      final res = await http.post(
        Uri.parse('http://$_hostIp:8088/api/mms-tts/speak'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(milliseconds: 2000));
      if (res.statusCode == 200) {
        _isSpeaking = false;
        startEchoDampeningTail();
        notifyListeners();
        return;
      }
    } catch (_) {}
    if (!kIsWeb) {
      try {
        if (_speechToText.isListening) await _speechToText.stop();
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setSpeechRate(_speechRate);
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setLanguage("hi-IN");
        await _flutterTts.speak(phoneticText);
        await Future.delayed(const Duration(milliseconds: 1200));
      } catch (e) {
        debugPrint("[TTS Error] $e");
      } finally {
        _isSpeaking = false;
        startEchoDampeningTail();
        await _notifyVoskMicMuteState(false);
        if (_isListening) _scheduleNativeReEngage(fromAbort: false);
        notifyListeners();
      }
    } else {
      _isSpeaking = false;
      startEchoDampeningTail();
      await _notifyVoskMicMuteState(false);
      notifyListeners();
    }
  }

  Future<void> speakHindiText(String text) async {
    if (text.trim().isEmpty) return;
    _isSpeaking = true;
    notifyListeners();
    registerSpokenTtsHash(text);
    await _notifyVoskMicMuteState(true);
    try {
      final res = await http.post(
        Uri.parse('http://$_hostIp:8088/api/mms-tts/speak'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(milliseconds: 2000));
      if (res.statusCode == 200) {
        _isSpeaking = false;
        startEchoDampeningTail();
        notifyListeners();
        return;
      }
    } catch (_) {}
    if (!kIsWeb) {
      try {
        if (_speechToText.isListening) await _speechToText.stop();
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setSpeechRate(_speechRate);
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setLanguage("hi-IN");
        await _flutterTts.speak(text);
        await Future.delayed(const Duration(milliseconds: 1200));
      } catch (e) {
        debugPrint("[TTS Error] $e");
      } finally {
        _isSpeaking = false;
        startEchoDampeningTail();
        await _notifyVoskMicMuteState(false);
        if (_isListening) _scheduleNativeReEngage(fromAbort: false);
        notifyListeners();
      }
    } else {
      _isSpeaking = false;
      startEchoDampeningTail();
      await _notifyVoskMicMuteState(false);
      notifyListeners();
    }
  }

  // ── Native STT: Init & Re-engage ─────────────────────────────────────────────
  Future<bool> initializeSpeech() async {
    if (_speechInitialized) return true;
    try {
      _speechInitialized = await _speechToText.initialize(
        onError: (val) {
          debugPrint("[STT Error] ${val.errorMsg}");
          if (!_isListening) return;
          _pendingListenStart = false;
          final isAbort = val.errorMsg.contains('aborted');
          if (isAbort) _consecutiveAborts++;
          _scheduleNativeReEngage(fromAbort: isAbort);
        },
        onStatus: (status) {
          debugPrint("[STT Status] $status");
          notifyListeners();
          if (status == 'listening') {
            _pendingListenStart = false;
            _isReEngaging = false;
            _consecutiveAborts = 0;
          }
          if (_isListening &&
              (status == 'done' || status == 'notListening' || status == 'doneListening')) {
            _pendingListenStart = false;
            _scheduleNativeReEngage(fromAbort: false);
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

  void _scheduleNativeReEngage({required bool fromAbort}) {
    if (!_isListening || _activeResultCallback == null) return;
    if (_nativeMicBusy) return;
    int delayMs;
    if (fromAbort && _consecutiveAborts > 0) {
      delayMs = (_baseRetryMs * (1 << (_consecutiveAborts - 1)))
          .clamp(_baseRetryMs, _maxRetryMs);
    } else {
      delayMs = 80;
    }
    _reEngageTimer?.cancel();
    _reEngageTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_isListening && !_speechToText.isListening && !_nativeMicBusy) {
        _doNativeReEngage();
      }
    });
  }

  Future<void> _doNativeReEngage() async {
    if (!_isListening || _activeResultCallback == null) return;
    if (_nativeMicBusy || _speechToText.isListening) return;
    _isReEngaging = true;
    try {
      try { await _speechToText.cancel(); } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 80));
      if (!_isListening) return;
      _pendingListenStart = true;
      await _speechToText.listen(
        onResult: (result) {
          _pendingListenStart = false;
          _consecutiveAborts = 0;
          final recognized = result.recognizedWords.trim();
          if (recognized.isNotEmpty) {
            _activePartialCallback?.call(HindiTextNormalizer.normalize(recognized));
            _processSpeechStream(recognized);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: _localeId ?? 'hi_IN',
          listenFor: const Duration(hours: 4),
          pauseFor: const Duration(seconds: 30),
          cancelOnError: false,
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          onDevice: false,
        ),
      );
    } catch (e) {
      debugPrint("[STT Re-Engage Error] $e");
      _pendingListenStart = false;
      if (e.toString().contains('InvalidStateError')) _consecutiveAborts++;
    } finally {
      _isReEngaging = false;
      notifyListeners();
    }
  }

  void _startNativeWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 4000), (_) {
      if (_isListening && !_speechToText.isListening && !_nativeMicBusy) {
        debugPrint('[STT Watchdog] Mic stalled — scheduling recovery');
        _scheduleNativeReEngage(fromAbort: false);
      }
    });
  }

  void _stopNativeWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  void reEngageMicIfEnabled() {
    if (!_isListening) return;
    if (kIsWeb) {
      // WebSttEngine manages its own restart
    } else if (!_speechToText.isListening && !_nativeMicBusy) {
      _scheduleNativeReEngage(fromAbort: false);
    }
  }

  // ── TTS engine init ──────────────────────────────────────────────────────────
  Future<void> _initTts() async {
    try {
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
      _flutterTts.setStartHandler(() { _isSpeaking = true;  notifyListeners(); });
      _flutterTts.setCompletionHandler(() { _isSpeaking = false; notifyListeners(); });
      _flutterTts.setErrorHandler((msg)  { _isSpeaking = false; notifyListeners(); });
    } catch (_) {}
  }

  void toggleAudioOutput() {
    _outputDevice = _outputDevice == AudioOutputDevice.bluetoothSpeaker
        ? AudioOutputDevice.deviceSpeaker
        : AudioOutputDevice.bluetoothSpeaker;
    notifyListeners();
  }

  void toggleAudioOutputDevice() => toggleAudioOutput();

  Future<void> startContinuousTeacherSpeechStream({
    required Function(String text, SpeechDeliveryMetrics? metrics) onChunkRecognized,
    Function(String partial)? onPartialRecognized,
    String localeId = 'hi_IN',
  }) =>
      startListening(
        onResultText: onChunkRecognized,
        onPartialText: onPartialRecognized,
        localeId: localeId,
      );

  Future<void> stopContinuousListening() => stopListening();

  // ── Public API: Start ────────────────────────────────────────────────────────
  Future<void> startListening({
    required Function(String text, SpeechDeliveryMetrics? metrics) onResultText,
    Function(String partial)? onPartialText,
    String localeId = 'hi_IN',
  }) async {
    _isListening          = true;
    _localeId             = localeId;
    _consecutiveAborts    = 0;
    _isReEngaging         = false;
    _pendingListenStart   = false;
    _lastSubmittedChunk   = '';
    _chunkStartTime       = null;
    _firstPartialTime     = null;
    _partialUpdateCount   = 0;
    _submittedSentenceHashes.clear();
    _submittedSentenceList.clear();
    _uncommittedBuffer    = '';
    _activeResultCallback  = onResultText;
    _activePartialCallback = onPartialText;

    // Fetch Vosk baseline index
    try {
      final res = await http.get(
        Uri.parse('http://$_hostIp:8086/api/vosk/status'),
      ).timeout(const Duration(milliseconds: 200));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _lastVoskIndex = data['total_sentences'] ?? 0;
      }
    } catch (_) { _lastVoskIndex = 0; }

    notifyListeners();
    _startVoskPoller();

    if (kIsWeb) {
      // ── WEB PATH: Chrome Direct SpeechRecognition (continuous=true) ──────────
      startWebStt(localeId, onResult: (text, isFinal) {
        if (text.trim().isEmpty) return;
        if (isFinal) {
          _processSpeechStream(text);
        } else {
          _activePartialCallback?.call(HindiTextNormalizer.normalize(text));
          // Real-time paragraph parsing for partial streams
          _handlePartialParagraphStream(text);
        }
      });
    } else {
      // ── NATIVE PATH: speech_to_text + watchdog
      await initializeSpeech();
      _startNativeWatchdog();
      if (_speechInitialized && !_speechToText.isListening) {
        await _doNativeReEngage();
      }
    }
  }

  // ── Vosk microservice sync ───────────────────────────────────────────────────
  Future<void> _syncChunkToVoskMicroservice(String text) async {
    try {
      await http.post(
        Uri.parse('http://127.0.0.1:8086/api/vosk/push-chunk'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(milliseconds: 500));
    } catch (_) {}
  }

  // ── Robust Paragraph & Sentence Stream Processing ────────────────────────────
  void _handlePartialParagraphStream(String partialText) {
    if (_activeResultCallback == null || !_isListening) return;

    final normalized = HindiTextNormalizer.normalize(partialText).trim();
    if (normalized.isEmpty) return;

    final now = DateTime.now();
    _chunkStartTime ??= now;
    _firstPartialTime ??= now;
    _partialUpdateCount++;

    // Split stream into coherent sentences
    final sentences = SpeechSegmenter.segmentParagraph(normalized);
    if (sentences.length > 1) {
      // All but the last sentence are complete! Emit them immediately
      for (int i = 0; i < sentences.length - 1; i++) {
        _emitSentenceIfNew(sentences[i]);
      }
      _uncommittedBuffer = sentences.last;
    } else if (sentences.isNotEmpty) {
      _uncommittedBuffer = sentences.first;
    }

    // Dynamic 500ms Gap / Pause Point Detector:
    // When the teacher stops speaking for 500ms, mark as a Pronounce Point and translate!
    _silenceFlushTimer?.cancel();
    if (_uncommittedBuffer.isNotEmpty) {
      _silenceFlushTimer = Timer(const Duration(milliseconds: 500), () {
        if (_isListening && _uncommittedBuffer.isNotEmpty) {
          debugPrint('[SpeechService Pronounce Point] Gap detected, finalizing: $_uncommittedBuffer');
          _emitSentenceIfNew(_uncommittedBuffer);
          _uncommittedBuffer = '';
        }
      });
    }
  }

  void _processSpeechStream(String rawRecognizedText) {
    if (_activeResultCallback == null || !_isListening) return;
    final normalized = HindiTextNormalizer.normalize(rawRecognizedText).trim();
    if (normalized.isEmpty) return;

    // Echo filter
    final dedupeCheck = normalized.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (_recentlySpokenTtsHashes.contains(dedupeCheck)) {
      debugPrint('[SpeechService Echo Suppressed] $normalized');
      return;
    }

    _silenceFlushTimer?.cancel();

    // Segment full paragraph into distinct complete sentences
    final sentences = SpeechSegmenter.segmentParagraph(normalized);
    for (final sentence in sentences) {
      _emitSentenceIfNew(sentence);
    }
    _uncommittedBuffer = '';
  }

  void _emitSentenceIfNew(String sentence) {
    final cleaned = HindiTextNormalizer.normalize(sentence).trim();
    if (cleaned.isEmpty) return;

    final key = cleaned.replaceAll(RegExp(r'[\s\.\।\?!\n,;\-]'), '').toLowerCase();
    if (key.isEmpty) return;

    // Self-emitted TTS echo filter
    if (_recentlySpokenTtsHashes.contains(key)) return;

    // Check if exact sentence was already emitted recently
    if (!_submittedSentenceHashes.contains(key)) {
      _submittedSentenceHashes.add(key);
      _submittedSentenceList.add(cleaned);
      _lastSubmittedChunk = cleaned;

      final now = DateTime.now();
      final chunkStart = _chunkStartTime ?? now;
      final firstPartial = _firstPartialTime ?? chunkStart;
      final durMs = now.difference(chunkStart).inMilliseconds.toDouble().clamp(200.0, 15000.0);
      final lagMs = now.difference(firstPartial).inMilliseconds.toDouble().clamp(100.0, 8000.0);
      final pauseMs = _lastEmittedSentenceEndTime != null
          ? chunkStart.difference(_lastEmittedSentenceEndTime!).inMilliseconds.toDouble().clamp(0.0, 5000.0)
          : 500.0;

      final deliveryMetrics = SpeechDeliveryMetrics(
        spokenText: cleaned,
        durationMs: durMs,
        partialUpdateCount: _partialUpdateCount.clamp(1, 30),
        partialToFinalMs: lagMs,
        interSentencePauseMs: pauseMs,
      );

      _lastEmittedSentenceEndTime = now;
      _chunkStartTime = null;
      _firstPartialTime = null;
      _partialUpdateCount = 0;

      _activeResultCallback?.call(cleaned, deliveryMetrics);
      _syncChunkToVoskMicroservice(cleaned);
      debugPrint('[SpeechService Sentence Emitted at Pronounce Point] $cleaned ($deliveryMetrics)');
    } else {
      debugPrint('[SpeechService Duplicate Sentence Skipped] $cleaned');
    }
  }

  // ── Public API: Stop ─────────────────────────────────────────────────────────
  Future<void> stopListening() async {
    _isListening        = false;
    _isReEngaging       = false;
    _pendingListenStart = false;
    _consecutiveAborts  = 0;
    _stopVoskPoller();
    _stopNativeWatchdog();
    _silenceFlushTimer?.cancel();
    _reEngageTimer?.cancel();

    if (_uncommittedBuffer.isNotEmpty) {
      _emitSentenceIfNew(_uncommittedBuffer);
      _uncommittedBuffer = '';
    }

    _activeResultCallback  = null;
    _activePartialCallback = null;
    notifyListeners();

    if (kIsWeb) {
      stopWebStt();
    } else if (_speechInitialized) {
      try { await _speechToText.stop(); } catch (_) {}
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopNativeWatchdog();
    _reEngageTimer?.cancel();
    _silenceFlushTimer?.cancel();
    _echoTailTimer?.cancel();
    if (kIsWeb) stopWebStt();
    super.dispose();
  }
}
