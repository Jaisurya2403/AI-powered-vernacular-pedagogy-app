// Conditional export: Chrome uses dart:html directly, everything else uses the stub.
export 'web_stt_engine_stub.dart'
    if (dart.library.html) 'web_stt_engine_web.dart';
