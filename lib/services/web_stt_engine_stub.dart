// Stub for non-web platforms (Android, iOS, Desktop).
// On these platforms speech_to_text uses native OS STT which works correctly.
typedef SttResultCallback = void Function(String text, bool isFinal);

void startWebStt(String locale, {required SttResultCallback onResult}) {}
void stopWebStt() {}
bool get webSttIsListening => false;
bool get webSttIsSupported => false;
