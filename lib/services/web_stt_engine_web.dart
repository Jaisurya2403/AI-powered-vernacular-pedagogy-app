// Web-only STT engine using the Chrome Web Speech API directly.
// Uses a persistent singleton SpeechRecognition instance with continuous=true,
// eliminating the InvalidStateError crash loop caused by rapid start/stop cycles.

// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

typedef SttResultCallback = void Function(String text, bool isFinal);

class WebSttEngine {
  WebSttEngine._();
  static final WebSttEngine _instance = WebSttEngine._();
  static WebSttEngine get instance => _instance;

  html.SpeechRecognition? _rec;
  bool _active = false;
  bool _isStarted = false;
  Timer? _restartTimer;
  String _locale = 'hi-IN';
  SttResultCallback? _callback;

  bool get isListening => _isStarted;

  static bool get isSupported {
    try {
      return js.context.hasProperty('SpeechRecognition') ||
          js.context.hasProperty('webkitSpeechRecognition');
    } catch (_) {
      return false;
    }
  }

  void start(String locale, {required SttResultCallback onResult}) {
    _locale = locale.replaceAll('_', '-');
    _callback = onResult;
    _active = true;
    if (!_isStarted) _launchRecognition();
  }

  void stop() {
    _active = false;
    _isStarted = false;
    _restartTimer?.cancel();
    final old = _rec;
    _rec = null;
    try {
      old?.abort();
    } catch (_) {}
    debugPrint('[WebSttEngine] Stopped.');
  }

  // Abort any old instance first (Chrome needs ~300ms to fully release the audio
  // track), then create a fresh recognition instance and call .start().
  void _launchRecognition() {
    if (!_active) return;
    if (_isStarted) return; // already live

    _restartTimer?.cancel();

    final old = _rec;
    _rec = null;
    if (old != null) {
      try {
        old.abort();
      } catch (_) {}
      // Give Chrome time to release the mic before we re-acquire it
      _restartTimer = Timer(const Duration(milliseconds: 350), () {
        if (_active) _createAndStart();
      });
    } else {
      _createAndStart();
    }
  }

  void _createAndStart() {
    if (!_active) return;

    _rec = html.SpeechRecognition();

    // ── Key settings ─────────────────────────────────────────────────────────
    // continuous=true  : Chrome keeps a single session alive across pauses.
    //                    Without this Chrome stops after every utterance and we
    //                    must restart — causing the InvalidStateError cascade.
    // interimResults=true: receive partial text while the user is still speaking.
    _rec!.continuous = true;
    _rec!.interimResults = true;
    _rec!.lang = _locale;
    _rec!.maxAlternatives = 1;

    _rec!.onStart.listen((_) {
      _isStarted = true;
      debugPrint('[WebSttEngine] Chrome STT started ($_locale, continuous=true)');
    });

    _rec!.onResult.listen((html.SpeechRecognitionEvent event) {
      try {
        // Use JS interop to read results because dart:html's SpeechRecognitionResult
        // does not expose the [] operator or properly typed isFinal.
        final jsEvent = js.JsObject.fromBrowserObject(event);
        final jsResults = jsEvent['results'];
        if (jsResults == null) return;
        final startIdx = (jsEvent['resultIndex'] as num?)?.toInt() ?? 0;
        final len = (jsResults['length'] as num?)?.toInt() ?? 0;
        for (int i = startIdx; i < len; i++) {
          final result = (jsResults as js.JsObject).callMethod('item', [i]) as js.JsObject?;
          if (result == null) continue;
          final isFinal = result['isFinal'] as bool? ?? false;
          final alt = result.callMethod('item', [0]) as js.JsObject?;
          final transcript = (alt?['transcript'] as String?)?.trim() ?? '';
          if (transcript.isEmpty) continue;
          _callback?.call(transcript, isFinal);
        }
      } catch (e) {
        debugPrint('[WebSttEngine] onResult processing error: $e');
      }
    });



    _rec!.onEnd.listen((_) {
      _isStarted = false;
      debugPrint('[WebSttEngine] Chrome STT ended — scheduling restart');
      if (_active) {
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(milliseconds: 250), () {
          if (_active) _createAndStart();
        });
      }
    });

    _rec!.addEventListener('error', (html.Event event) {
      _isStarted = false;
      // dart:html types onError as plain Event; use JS interop for error code
      String error = 'unknown';
      try {
        error =
            js.JsObject.fromBrowserObject(event)['error']?.toString() ??
                'unknown';
      } catch (_) {}
      debugPrint('[WebSttEngine] Chrome STT error: $error');

      if (!_active) return;

      _rec = null; // Force a fresh instance on next attempt

      int delayMs;
      switch (error) {
        case 'no-speech':
          delayMs = 150; // Normal pause — restart quickly
          break;
        case 'aborted':
          delayMs = 1000; // Chrome killed us — back off
          break;
        case 'network':
          delayMs = 2500; // Google's STT service issue — wait longer
          break;
        case 'not-allowed':
        case 'service-not-allowed':
          _active = false;
          debugPrint('[WebSttEngine] Microphone permission denied — giving up.');
          return;
        default:
          delayMs = 700;
      }

      _restartTimer?.cancel();
      _restartTimer = Timer(Duration(milliseconds: delayMs), () {
        if (_active) _createAndStart();
      });
    });

    try {
      _rec!.start();
    } catch (e) {
      _isStarted = false;
      _rec = null;
      debugPrint('[WebSttEngine] .start() threw: $e — retrying in 1.2s');
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(milliseconds: 1200), () {
        if (_active) _createAndStart();
      });
    }
  }
}

// Top-level helpers consumed by speech_service.dart via the conditional export
void startWebStt(String locale, {required SttResultCallback onResult}) {
  WebSttEngine.instance.start(locale, onResult: onResult);
}

void stopWebStt() {
  WebSttEngine.instance.stop();
}

bool get webSttIsListening => WebSttEngine.instance.isListening;
bool get webSttIsSupported => WebSttEngine.isSupported;
