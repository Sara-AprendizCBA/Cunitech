import 'package:edge_tts/edge_tts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cunitech/services/neural_voice.dart';
import 'package:cunitech/services/neural_voice_engine_io.dart';

Voice _voz(String shortName, String locale) => Voice(
      name: shortName,
      shortName: shortName,
      gender: 'Female',
      locale: locale,
      language: locale.split('-').first,
      friendlyName: shortName,
      status: 'Success',
      suggestedCodec: 'audio-24khz-48kbitrate-mono-mp3',
    );

void main() {
  group('voz neuronal', () {
    test('el motor neuronal esta disponible en esta plataforma', () {
      // En el VM (y en movil/escritorio) hay voz neuronal; en Web el motor
      // delega en el motor de voz del sistema.
      expect(NeuralVoice.instance.hayVozNeural, isTrue);
    });

    test('elige la voz neuronal preferida en espanol', () {
      final voces = [
        _voz('en-US-JennyNeural', 'en-US'),
        _voz('es-ES-ElviraNeural', 'es-ES'),
        _voz('es-MX-DaliaNeural', 'es-MX'),
      ];
      expect(NeuralVoiceEngine.elegirVoz(voces), 'es-MX-DaliaNeural');
    });

    test('si no hay la preferida, usa otra en espanol', () {
      // Elvira es la segunda preferida, asi que gana a la argentina.
      final voces = [
        _voz('es-ES-ElviraNeural', 'es-ES'),
        _voz('es-AR-ElenaNeural', 'es-AR'),
      ];
      expect(NeuralVoiceEngine.elegirVoz(voces), 'es-ES-ElviraNeural');
    });

    test('si ninguna es la preferida, usa la que haya en espanol', () {
      final voces = [
        _voz('es-AR-ElenaNeural', 'es-AR'),
        _voz('es-CL-CamilaNeural', 'es-CL'),
      ];
      expect(NeuralVoiceEngine.elegirVoz(voces), 'es-AR-ElenaNeural');
    });

    test('si no hay ninguna voz en espanol, usa la de por defecto', () {
      final voces = [
        _voz('en-US-JennyNeural', 'en-US'),
        _voz('fr-FR-DeniseNeural', 'fr-FR'),
      ];
      expect(
        NeuralVoiceEngine.elegirVoz(voces),
        NeuralVoiceEngine.vocesEspanol.first,
      );
    });

    test('la lista de voces es solo la de español en el servicio', () {
      // Comprueba que las voces por defecto son neurales de Microsoft Edge.
      for (final voz in NeuralVoiceEngine.vocesEspanol) {
        expect(voz.startsWith('es-'), isTrue);
        expect(voz.endsWith('Neural'), isTrue);
      }
    });
  });
}
