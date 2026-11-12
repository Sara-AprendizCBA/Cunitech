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

  /// Nombre de la voz que se ha elegido (vacio si se usa la del sistema).
  String _vozSeleccionada = '';

  /// Voz con la que se esta leyendo. Sirve para diagnostico.
  String get vozSeleccionada => _vozSeleccionada;

  /// Idiomas que se prueban, en orden, para quedarse con el primero que
  /// soporte el motor (varia entre Android, Web, Windows...).
  static const List<String> _idiomas = ['es-ES', 'es_MX', 'es_ES', 'es'];

  /// Velocidad natural: la de por defecto (0.5) suena algo apresurada.
  static const double _velocidad = 0.45;

  /// Tono un poco mas calido que el estandar (1.0).
  static const double _tono = 1.05;

  static const double _volumen = 1.0;

  /// Prepara el motor: voz en español, velocidad y tono amables y la mejor
  /// voz disponible en el dispositivo.
  Future<void> inicializar() async {
    if (_inicializado) return;

    for (final idioma in _idiomas) {
      final ok = await _intentar(() => _tts.setLanguage(idioma));
      if (ok == true) break;
    }

    // Cada ajuste por separado: en Web el motor puede no soportar alguno.
    await _intentar(() => _tts.setSpeechRate(_velocidad));
    await _intentar(() => _tts.setPitch(_tono));
    await _intentar(() => _tts.setVolume(_volumen));

    await _seleccionarMejorVoz();

    _tts.setCompletionHandler(() => hablando.value = false);
    _tts.setCancelHandler(() => hablando.value = false);
    _tts.setErrorHandler((_) => hablando.value = false);

    _inicializado = true;
  }

  /// Busca la mejor voz en español del dispositivo y la activa.
  ///
  /// Si el dispositivo no expone la lista de voces, o no hay ninguna en
  /// español, o el motor no acepta `setVoice` (caso tipico en Web), se sigue
  /// adelante con la voz por defecto: nunca debe romper la lectura.
  Future<void> _seleccionarMejorVoz() async {
    try {
      final voces = await _tts.getVoices;
      final mejor = elegirMejorVoz(voces is List ? voces : const []);
      if (mejor == null) return;

      final ok = await _intentar(
        () => _tts.setVoice({
          'name': (mejor['name'] ?? '').toString(),
          'locale': (mejor['locale'] ?? '').toString(),
        }),
      );
      if (ok == true) {
        _vozSeleccionada = (mejor['name'] ?? '').toString();
      }
    } catch (e) {
      logger.w('No se pudo elegir la voz del dispositivo', error: e);
    }
  }

  /// Elige la mejor voz en español de la lista de voces del dispositivo.
  ///
  /// Devuelve `null` si no hay ninguna voz en español.
  static Map<String, dynamic>? elegirMejorVoz(List<dynamic> voces) {
    final candidatas = <Map<String, dynamic>>[];
    for (final voz in voces) {
      if (voz is! Map) continue;
      final locale = (voz['locale'] ?? '').toString();
      if (!locale.toLowerCase().startsWith('es')) continue;
      candidatas.add(voz.cast<String, dynamic>());
    }
    if (candidatas.isEmpty) return null;

    candidatas.sort((a, b) => puntuarVoz(b).compareTo(puntuarVoz(a)));

    final mejor = candidatas.first;
    return (mejor['name'] ?? '').toString().isEmpty ? null : mejor;
  }

  /// Puntua una voz: cuanto mas natural, mas alto.
  ///
  /// Prioriza las voces de red del sistema (las que suenan mas naturales),
  /// luego la calidad y la region, y desempata con el nombre mas descriptivo.
  static int puntuarVoz(Map<String, dynamic> voz) {
    final nombre = (voz['name'] ?? '').toString().toLowerCase();
    final locale = (voz['locale'] ?? '').toString().toLowerCase();
    final calidad = (voz['quality'] ?? '').toString().toLowerCase();

    var puntos = 0;

    // Voces "network" / "neural" / "premium": las mas naturales del sistema.
    if (nombre.contains('network')) puntos += 12;
    if (nombre.contains('neural')) puntos += 12;
    if (nombre.contains('premium')) puntos += 10;

    // Calidad (solo la informan iOS y macOS).
    if (calidad == 'enhanced') {
      puntos += 8;
    } else if (calidad == 'high') {
      puntos += 6;
    } else if (calidad == 'normal') {
      puntos += 2;
    }

    // Region preferida.
    if (locale == 'es-es') {
      puntos += 5;
    } else if (locale == 'es-mx' || locale == 'es_419') {
      puntos += 3;
    }

    // Desempate: el nombre mas descriptivo.
    puntos += nombre.length.clamp(0, 10);
    return puntos;
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
