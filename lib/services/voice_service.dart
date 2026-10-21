// lib/services/voice_service.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/utils/logger.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _inicializado = false;

  Future<bool> inicializar() async {
    if (_inicializado) return true;
    try {
      final disponible = await _speechToText.initialize();
      await _configurarTts();
      _inicializado = disponible;
      return disponible;
    } catch (e) {
      logger.e('Error inicializando VoiceService', error: e);
      return false;
    }
  }

  Future<void> _configurarTts() async {
    try {
      await _flutterTts.setLanguage('es_ES');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
    } catch (e) {
      logger.e('Error configurando FlutterTts', error: e);
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
      localeId: 'es_ES',
      onResult: (resultado) {
        textoReconocido = resultado.recognizedWords;
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: false,
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
    if (texto.trim().isEmpty) return;
    try {
      if (!_inicializado) {
        await _configurarTts();
      }
      await _flutterTts.speak(texto);
    } catch (e) {
      logger.e('Error hablando con TTS', error: e);
    }
  }

  Future<void> detener() async {
    try {
      await _speechToText.stop();
      await _flutterTts.stop();
    } catch (e) {
      logger.e('Error deteniendo VoiceService', error: e);
    }
  }

  bool get escuchando => _speechToText.isListening;
}
