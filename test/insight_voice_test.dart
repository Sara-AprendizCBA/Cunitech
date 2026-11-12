import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cunitech/models/insight_recomendacion.dart';
import 'package:cunitech/services/insight_service.dart';
import 'package:cunitech/services/tts_service.dart';
import 'package:cunitech/widgets/insight_panel_dialog.dart';

/// Servicio de insights con datos en memoria.
class _FakeInsightService extends InsightService {
  @override
  Future<InsightPanel> obtenerRecomendaciones() async => const InsightPanel(
        diagnosticoGeneral:
            'He notado que la mortalidad ha subido un 10%. Te sugiero revisar '
            'la ventilacion de las jaulas.',
        recomendaciones: [
          InsightRecomendacion(
            titulo: 'Revisar ventilacion',
            detalle: 'Aumenta el flujo de aire en las jaulas del sector norte.',
            prioridad: 'alta',
            impacto: 'Reduce la mortalidad en un 3-5%',
          ),
          InsightRecomendacion(
            titulo: 'Control de temperatura',
            detalle: 'Registra la temperatura dos veces al dia.',
            prioridad: 'media',
          ),
        ],
      );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://invalid-host-for-tests.invalid',
      publishableKey: 'sb_publishable_test',
    );
  });

  group('limpieza del texto para la voz', () {
    test('quita markdown, emojis y colapsa espacios', () {
      final limpio = TtsService.prepararTexto(
        '**Alerta**: mortalidad 📈 up 10%.\nRevisa   la jaula.',
      );
      expect(limpio, isNot(contains('*')));
      expect(limpio, isNot(contains('📈')));
      expect(limpio.contains('  '), isFalse);
      expect(limpio, 'Alerta : mortalidad up 10%. Revisa la jaula.');
    });

    test('deja intacto el texto normal', () {
      expect(
        TtsService.prepararTexto('Mortalidad alta en la jaula 12.'),
        'Mortalidad alta en la jaula 12.',
      );
    });
  });

  testWidgets('el panel muestra el boton de voz y el analisis',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsightPanelDialog(service: _FakeInsightService()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CUNITECH Insight'), findsOneWidget);
    expect(find.byTooltip('Leer en voz alta'), findsOneWidget);
    expect(find.textContaining('mortalidad ha subido'), findsOneWidget);
    expect(find.text('Revisar ventilacion'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 10));
  });
}
