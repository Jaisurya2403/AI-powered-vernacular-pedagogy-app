void speakWebUtterance(String text) {
  // No-op stub on non-web platforms (Android/iOS/Desktop use FlutterTTS / HTTP Microservice)
}

bool isWebSpeechActive() {
  return false;
}
