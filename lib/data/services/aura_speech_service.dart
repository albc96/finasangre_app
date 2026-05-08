import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AuraSpeechService {
  AuraSpeechService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool initialized = false;
  String? error;

  Future<bool> init() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      error = 'Necesito permiso de microfono para escuchar tu consulta.';
      return false;
    }
    initialized = await _speech.initialize(
      onError: (event) => error = event.errorMsg,
      onStatus: (_) {},
    );
    if (!initialized) {
      error = 'No pude iniciar el reconocimiento de voz en este dispositivo.';
    }
    return initialized;
  }

  Future<void> startListening(void Function(String text) onResult) async {
    if (!initialized && !await init()) return;
    await _speech.listen(
      localeId: 'es_CL',
      onResult: (result) {
        if (result.recognizedWords.trim().isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() => _speech.stop();
}
