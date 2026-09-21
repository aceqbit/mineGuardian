import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) => print('Voice recognition error: $error'),
        onStatus: (status) => print('Voice recognition status: $status'),
      );
      return _isAvailable;
    } catch (e) {
      _isAvailable = false;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
