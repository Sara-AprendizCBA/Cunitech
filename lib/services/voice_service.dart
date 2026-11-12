// lib/services/voice_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/utils/logger.dart';
import 'tts_service.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _inicializado = false;

  Future<bool> inicializar() async {
    if (_inicializado) return true;
    try {
      final disponible = await _speechToText.initialize();
      await TtsService.instance.inicializar();
      _inicializado = disponible;
      return disponible;
    } catch (e) {
      logger.e('Error inicializando VoiceService', error: e);
      return false;
    }
  }

  Future<String> escuchar() async {
    if (!_inicializado) {
      final ok = await inicializar();
      if (!ok) throw Exception('Micrófono no disponible');
    }

    if (!_speechToText.isAvailable) {
      throw Exception('Reconocimiento de voz no disponible');
    }

    String textoReconocido = '';
    await _speechToText.listen(
      onResult: (resultado) {
        textoReconocido = resultado.recognizedWords;
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: 'es_ES',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
      ),
    );

    await Future.delayed(const Duration(seconds: 4));
    await _speechToText.stop();

    final texto = textoReconocido.trim();
    if (texto.isEmpty) {
      throw Exception('No se escuchó nada');
    }
    return texto;
  }

  Future<void> hablar(String texto) async {
    await TtsService.instance.hablar(texto);
  }

  Future<void> detener() async {
    try {
      await _speechToText.stop();
    } catch (e) {
      logger.e('Error deteniendo el reconocimiento de voz', error: e);
    }
    await TtsService.instance.detener();
  }

  bool get escuchando => _speechToText.isListening;
}
