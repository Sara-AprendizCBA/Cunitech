import 'package:flutter_test/flutter_test.dart';

import 'package:cunitech/services/tts_service.dart';

void main() {
  group('eleccion de la mejor voz en espanol', () {
    // Vozes tipicas de Android (Google TTS) y de iOS.
    final vocesAndroid = [
      {'name': 'es-us-x-esd-network', 'locale': 'es-US'},
      {'name': 'es-ES-language', 'locale': 'es-ES'},
      {'name': 'en-us-x-sfg-network', 'locale': 'en-US'},
      {'name': 'es-us-x-ela-network', 'locale': 'es-US'},
    ];

    test('elige la voz de red (suena mas natural)', () {
      final mejor = TtsService.elegirMejorVoz(vocesAndroid);
      expect(mejor, isNotNull);
      expect((mejor!['name'] as String).contains('network'), isTrue);
    });

    test('ignora las voces que no son de espanol', () {
      final mejor = TtsService.elegirMejorVoz([
        {'name': 'en-us-x-sfg-network', 'locale': 'en-US'},
        {'name': 'fr-fr-x-nda-network', 'locale': 'fr-FR'},
      ]);
      expect(mejor, isNull);
    });

    test('devuelve null si no hay voces', () {
      expect(TtsService.elegirMejorVoz(const []), isNull);
      expect(TtsService.elegirMejorVoz(const ['no soy una voz']), isNull);
    });

    test('en Web (sin quality) tambien elige bien', () {
      // En Web getVoices solo devuelve name y locale.
      final mejor = TtsService.elegirMejorVoz([
        {'name': 'Microsoft Helena Online (Natural) - Spanish (Spain)', 'locale': 'es-ES'},
        {'name': 'Microsoft Laura Online (Natural) - Spanish (Spain)', 'locale': 'es-ES'},
      ]);
      expect(mejor, isNotNull);
      expect((mejor!['locale'] as String), 'es-ES');
    });

    test('la calidad enhanced de iOS gana', () {
      final mejor = TtsService.elegirMejorVoz([
        {
          'name': 'Mónica',
          'locale': 'es-ES',
          'quality': 'default',
        },
        {
          'name': 'Monica (Enhanced)',
          'locale': 'es-ES',
          'quality': 'enhanced',
        },
      ]);
      expect((mejor!['name'] as String).contains('Enhanced'), isTrue);
    });

    test('la puntuacion ordena de mas natural a menos', () {
      final red = TtsService.puntuarVoz({
        'name': 'es-us-x-esd-network',
        'locale': 'es-US',
      });
      final normal = TtsService.puntuarVoz({
        'name': 'es-ES-language',
        'locale': 'es-ES',
      });
      expect(red, greaterThan(normal));
    });
  });
}
