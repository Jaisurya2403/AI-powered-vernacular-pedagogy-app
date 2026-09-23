import 'package:flutter_test/flutter_test.dart';
import 'package:vernacular_pedagogy/services/speech_service.dart';
import 'package:vernacular_pedagogy/engine/hindi_text_normalizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hybrid STT & Keep-Alive Watchdog Unit Tests', () {
    late SpeechService speechService;

    setUp(() {
      speechService = SpeechService();
    });

    tearDown(() {
      speechService.dispose();
    });

    test('SpeechService initial state is not listening', () {
      expect(speechService.isListening, isFalse);
    });

    test('Audio output device toggle switches between Bluetooth and Device speaker', () {
      expect(speechService.outputDevice, equals(AudioOutputDevice.bluetoothSpeaker));
      speechService.toggleAudioOutputDevice();
      expect(speechService.outputDevice, equals(AudioOutputDevice.deviceSpeaker));
      speechService.toggleAudioOutputDevice();
      expect(speechService.outputDevice, equals(AudioOutputDevice.bluetoothSpeaker));
    });

    test('Speech rate setting updates state', () async {
      await speechService.setSpeechRate(0.5);
      expect(speechService.speechRate, equals(0.5));
    });

    test('Continuous sentence normalization removes excess spacing and normalizes punctuation', () {
      const rawSentence = " सुबह के  सात   बजे हैं aur dhoop nikal aayi hai. ";
      final normalized = HindiTextNormalizer.normalize(rawSentence);
      expect(normalized, equals("सुबह के सात बजे हैं aur dhoop nikal aayi hai ."));
    });
  });
}
