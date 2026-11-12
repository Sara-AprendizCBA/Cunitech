import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/utils/logger.dart';

/// Motor de lectura en voz (texto a habla).
///
/// Es un singleton para que la app use una sola instancia del motor: asi el
/// Insight y el asistente de voz nunca se pisan la voz entre si.
class TtsService {
  static final TtsService instance = TtsService._();

  TtsService._();

  final FlutterTts _tts = FlutterTts();

  bool _inicializado = false;

  /// `true` mientras el motor está leyendo en voz alta.
  final ValueNotifier<bool> hablando = ValueNotifier<bool>(false);

  /// Idiomas que se prueban, en orden, para quedarse con el primero que
  /// soporte el motor (varia entre Android, Web, Windows...).
  static const List<String> _idiomas = ['es-ES', 'es_MX', 'es_ES', 'es'];

  /// Prepara el motor: voz en español, velocidad y tono amables.
  Future<void> inicializar() async {
    if (_inicializado) return;

    for (final idioma in _idiomas) {
      final ok = await _intentar(() => _tts.setLanguage(idioma));
      if (ok == true) break;
    }

    // Cada ajuste por separado: en Web el motor puede no soportar alguno.
    await _intentar(() => _tts.setSpeechRate(0.5));
    await _intentar(() => _tts.setPitch(1.0));
    await _intentar(() => _tts.setVolume(1.0));

    _tts.setCompletionHandler(() => hablando.value = false);
    _tts.setCancelHandler(() => hablando.value = false);
    _tts.setErrorHandler((_) => hablando.value = false);

    _inicializado = true;
  }

  /// Lee un texto en voz alta.
  Future<void> hablar(String texto) async {
    final limpio = prepararTexto(texto);
    if (limpio.isEmpty) return;

    await inicializar();
    hablando.value = true;
    try {
      await _tts.speak(limpio);
    } catch (e) {
      logger.e('Error hablando con el TTS', error: e);
      hablando.value = false;
    }
  }

  /// Detiene la lectura en voz alta.
  Future<void> detener() async {
    try {
      await _tts.stop();
    } catch (e) {
      logger.e('Error deteniendo el TTS', error: e);
    }
    hablando.value = false;
  }

  /// Limpia el texto para que suene bien: quita markdown, emojis y signs.
  static String prepararTexto(String texto) {
    // Quita los emojis y simbolos decorativos (0x2600-0x27BF y 0x1F000-0x1FAFF):
    // el motor de voz los lee como ruido.
    final sinEmojis = String.fromCharCodes(
      texto.runes
          .where((code) =>
              !(code >= 0x2600 && code <= 0x27BF) &&
              !(code >= 0x1F000 && code <= 0x1FAFF))
          .toList(),
    );

    // Luego el markdown y los espacios (al final, para que no queden huecos
    // dobles donde estaba un emoji).
    return sinEmojis
        .replaceAll(RegExp(r'[*_`#>]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Ejecuta una configuracion sin romper el resto si el motor no la soporta.
  Future<bool?> _intentar(Future<dynamic> Function() accion) async {
    try {
      await accion();
      return true;
    } catch (e) {
      logger.w('El motor de voz no soporta una configuracion', error: e);
      return false;
    }
  }
}
