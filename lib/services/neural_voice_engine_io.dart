import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:edge_tts/edge_tts.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/logger.dart';

/// Motor de voz neuronal de Microsoft Edge para Android, iOS y escritorio.
///
/// Genera el audio MP3 con una voz neuronal en español y lo reproduce desde
/// memoria, sin escribir nada en disco.
class NeuralVoiceEngine {
  /// Voces neuronales en español, de mas natural a menos.
  ///
  /// Dalia (Mexico) y Elvira (España) suenan muy humanas; Jenny (USA) es la
  /// reserva por si el servicio no ofrece las dos primeras.
  static const List<String> vocesEspanol = [
    'es-MX-DaliaNeural',
    'es-ES-ElviraNeural',
    'es-US-JennyNeural',
  ];

  /// Reproductor de audio. Se crea la primera vez que se usa para no
  /// levantar canales de plataforma al abrir la app.
  AudioPlayer? _player;

  AudioPlayer get _reproductor => _player ??= AudioPlayer();

  final ValueNotifier<bool> _hablando = ValueNotifier<bool>(false);
  StreamSubscription<void>? _suscripcionFin;

  bool get hayVozNeural => true;

  ValueListenable<bool> get hablando => _hablando;

  /// Genera el MP3 con la voz neural y lo reproduce.
  ///
  /// Si el texto esta vacio no hace nada. Si ya sonaba, se detiene.
  Future<void> hablar(String texto) async {
    if (texto.trim().isEmpty) return;
    if (_hablando.value) {
      await detener();
      return;
    }

    try {
      _hablando.value = true;

      final voz = await _mejorVoz();
      final tts = Communicate(text: texto, voice: voz);
      final bytes = await tts.toBytes();

      if (bytes.isEmpty) {
        _hablando.value = false;
        return;
      }

      await _reproductor.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
      _escucharFin();
    } catch (e) {
      logger.e('Error con Edge TTS', error: e);
      _hablando.value = false;
    }
  }

  /// Detiene la reproduccion.
  Future<void> detener() async {
    try {
      await _reproductor.stop();
    } catch (e) {
      logger.e('Error deteniendo Edge TTS', error: e);
    }
    _hablando.value = false;
  }

  /// Libera el reproductor.
  void dispose() {
    _suscripcionFin?.cancel();
    _player?.dispose();
    _hablando.dispose();
  }

  /// Elige la mejor voz neural en español que ofrezca el servicio.
  Future<String> _mejorVoz() async {
    try {
      final voces = await listVoices();
      return elegirVoz(voces);
    } catch (e) {
      logger.w('No se pudo listar las voces de Edge TTS', error: e);
    }
    // Si no se puede consultar la lista, se usa la voz preferida por defecto.
    return vocesEspanol.first;
  }

  /// Elige la mejor voz en español de una lista de voces del servicio.
  ///
  /// Prioriza [vocesEspanol] (las mas naturales) y, si ninguna esta
  /// disponible, escoge la primera en español por orden alfabetico.
  static String elegirVoz(List<Voice> voces) {
    final disponibles = voces
        .where((v) => v.shortName.toLowerCase().startsWith('es-'))
        .map((v) => v.shortName)
        .toSet();

    for (final preferida in vocesEspanol) {
      if (disponibles.contains(preferida)) return preferida;
    }
    if (disponibles.isNotEmpty) {
      final ordenadas = disponibles.toList()..sort();
      return ordenadas.first;
    }
    return vocesEspanol.first;
  }

  /// Cuando termina el audio se actualiza el estado.
  void _escucharFin() {
    _suscripcionFin?.cancel();
    _suscripcionFin = _reproductor.onPlayerComplete.listen((_) {
      _hablando.value = false;
    });
  }
}
