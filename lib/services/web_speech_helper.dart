import 'package:flutter/foundation.dart';

// Conditional import for Web vs Non-Web platforms
import 'web_speech_stub.dart'
    if (dart.library.html) 'web_speech_web.dart';

abstract class WebSpeechHelper {
  static void speakOnWeb(String text) {
    if (kIsWeb) {
      speakWebUtterance(text);
    }
  }
}
