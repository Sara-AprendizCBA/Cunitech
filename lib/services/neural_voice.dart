import 'package:flutter/foundation.dart';

import 'neural_voice_engine_stub.dart'
    if (dart.library.io) 'neural_voice_engine_io.dart' as engine;

/// Voz neuronal de Microsoft Edge (gratis y sin API key) para CUNITECH Insight.
///
/// En Android, iOS y escritorio usa las voces neuronales de Edge (mucho mas
/// naturales que la voz del sistema). En **Web no es posible**: el paquete
/// `edge_tts` habla por WebSocket de `dart:io`, que no existe en el
/// navegador, asi que alli se usa automaticamente el motor de voz del
/// dispositivo.
///
/// Mira [hayVozNeural] para saber con que motor se va a leer.
class NeuralVoice {
  static final NeuralVoice instance = NeuralVoice._();

  NeuralVoice._();

  /// Motor de la plataforma actual (neuronal o del sistema).
  final engine.NeuralVoiceEngine _motor = engine.NeuralVoiceEngine();

  /// `true` si en esta plataforma hay voz neuronal disponible.
  bool get hayVozNeural => _motor.hayVozNeural;

  /// `true` mientras se esta leyendo en voz alta.
  ValueListenable<bool> get hablando => _motor.hablando;

  /// Lee un texto en voz alta (neuronal si se puede, del sistema si no).
  Future<void> hablar(String texto) => _motor.hablar(texto);

  /// Detiene la lectura en voz alta.
  Future<void> detener() => _motor.detener();
}
