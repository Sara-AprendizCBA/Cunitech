import 'package:flutter/foundation.dart';

import '../core/utils/logger.dart';
import 'tts_service.dart';

/// Motor de voz para Web.
///
/// El paquete `edge_tts` usa WebSocket de `dart:io` y no compila en el
/// navegador, asi que en Web se delega en el motor de voz del dispositivo
/// (flutter_tts), que si funciona en el navegador.
class NeuralVoiceEngine {
  bool get hayVozNeural => false;

  ValueListenable<bool> get hablando => TtsService.instance.hablando;

  Future<void> hablar(String texto) async {
    if (texto.trim().isEmpty) return;
    await TtsService.instance.hablar(texto);
  }

  Future<void> detener() async {
    logger.d('Voz del sistema detenida (Web sin voz neuronal)');
    await TtsService.instance.detener();
  }
}
