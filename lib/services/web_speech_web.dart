// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:collection';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class WebSpeechQueueManager {
  static final Queue<String> _queue = Queue<String>();
  static bool _isPlaying = false;
  static List<html.SpeechSynthesisVoice> _cachedVoices = [];

  static void _initVoices() {
    try {
      if (html.window.speechSynthesis != null) {
        _cachedVoices = html.window.speechSynthesis!.getVoices();
        html.window.speechSynthesis!.addEventListener('voiceschanged', (_) {
          _cachedVoices = html.window.speechSynthesis!.getVoices();
          debugPrint('[WebSpeechQueue] Loaded ${_cachedVoices.length} browser speech voices');
        });
      }
    } catch (_) {}
  }

  static void enqueue(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    if (_cachedVoices.isEmpty) {
      _initVoices();
    }

    _queue.addLast(cleanText);
    debugPrint('[WebSpeechQueue] Enqueued: "$cleanText" (Queue depth: ${_queue.length})');

    if (!_isPlaying) {
      _processNextInQueue();
    }
  }

  static void _processNextInQueue() {
    if (_queue.isEmpty) {
      _isPlaying = false;
      return;
    }

    _isPlaying = true;
    final text = _queue.removeFirst();
    debugPrint('[WebSpeechQueue] Processing phrase: "$text"');

    _speakViaWebSpeechSynthesis(text);
  }

  static void _speakViaWebSpeechSynthesis(String text) {
    try {
      if (html.window.speechSynthesis == null) {
        _processNextInQueue();
        return;
      }

      // 1. Resume audio context if browser paused speech synthesis
      if (html.window.speechSynthesis!.paused == true) {
        html.window.speechSynthesis!.resume();
      }

      // 2. Refresh voice list if needed
      if (_cachedVoices.isEmpty) {
        _cachedVoices = html.window.speechSynthesis!.getVoices();
      }

      // 3. Instantiate SpeechSynthesisUtterance
      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.volume = 1.0;
      utterance.rate = 0.88;
      utterance.pitch = 1.0;

      // 4. Select best available Hindi or Indian voice profile
      html.SpeechSynthesisVoice? matchedVoice;

      for (final voice in _cachedVoices) {
        final lang = voice.lang?.toLowerCase() ?? '';
        final name = voice.name?.toLowerCase() ?? '';
        if (lang.contains('hi') || name.contains('hindi')) {
          matchedVoice = voice;
          break;
        }
      }

      if (matchedVoice == null) {
        for (final voice in _cachedVoices) {
          final lang = voice.lang?.toLowerCase() ?? '';
          if (lang.contains('in')) {
            matchedVoice = voice;
            break;
          }
        }
      }

      if (matchedVoice != null) {
        utterance.voice = matchedVoice;
        utterance.lang = matchedVoice.lang;
      } else {
        utterance.lang = 'hi-IN';
      }

      // Safety timeout timer (max 4 seconds per phrase) to prevent queue hanging
      Timer? safetyTimer;
      bool completed = false;

      void markCompleted(String reason) {
        if (!completed) {
          completed = true;
          safetyTimer?.cancel();
          debugPrint('[WebSpeechQueue] Completed ($reason) for: "$text"');
          // Short 100ms gap before playing next queued phrase
          Timer(const Duration(milliseconds: 100), () {
            _processNextInQueue();
          });
        }
      }

      safetyTimer = Timer(const Duration(milliseconds: 4000), () {
        markCompleted('safety_timeout');
      });

      utterance.onEnd.listen((_) {
        markCompleted('onEnd');
      });

      utterance.onError.listen((err) {
        markCompleted('onError: $err');
      });

      html.window.speechSynthesis!.speak(utterance);
      debugPrint('[WebSpeechQueue] Spoke utterance: "$text" (Voice: ${utterance.voice?.name ?? "default"})');
    } catch (e) {
      debugPrint('[WebSpeechQueue Exception] $e');
      _processNextInQueue();
    }
  }
}

void speakWebUtterance(String text) {
  WebSpeechQueueManager.enqueue(text);
}
