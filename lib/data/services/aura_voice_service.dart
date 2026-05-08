import 'package:flutter_tts/flutter_tts.dart';

class AuraVoiceService {
  AuraVoiceService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.05);
    await setVoice();
    _ready = true;
  }

  Future<void> setVoice() async {
    final voices = await _tts.getVoices;
    if (voices is List) {
      final esCl = voices.whereType<Map>().where((voice) {
        return '${voice['locale']}'.toLowerCase() == 'es-cl';
      }).firstOrNull;
      final esEs = voices.whereType<Map>().where((voice) {
        return '${voice['locale']}'.toLowerCase() == 'es-es';
      }).firstOrNull;
      final selected = esCl ?? esEs;
      if (selected != null) {
        await _tts.setVoice(Map<String, String>.from(selected));
        return;
      }
    }
    await _tts.setLanguage('es-CL');
  }

  Future<void> setRate(double value) => _tts.setSpeechRate(value);

  Future<void> setPitch(double value) => _tts.setPitch(value);

  Future<void> speak(String text) async {
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
