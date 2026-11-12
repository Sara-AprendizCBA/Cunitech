import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cunitech/controllers/auth_controller.dart';
import 'package:cunitech/controllers/rabbit_controller.dart';
import 'package:cunitech/models/peso_registro.dart';
import 'package:cunitech/models/rabbit.dart';
import 'package:cunitech/screens/rabbits/rabbit_weight_history_section.dart';
import 'package:cunitech/services/peso_service.dart';

/// Servicio de pesajes con datos en memoria (no toca Supabase).
class _FakePesoService extends PesoService {
  _FakePesoService(this.registros);

  List<PesoRegistro> registros;

  @override
  Future<List<PesoRegistro>> getHistorial(String conejoId) async => registros;

  @override
  Future<bool> registrar({
    required String conejoId,
    required DateTime fecha,
    required double pesoKg,
    String? notas,
  }) async {
    registros = [
      ...registros,
      PesoRegistro(
        id: '${registros.length}',
        conejoId: int.parse(conejoId),
        fecha: fecha,
        pesoKg: pesoKg,
      ),
    ];
    return true;
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://invalid-host-for-tests.invalid',
      publishableKey: 'sb_publishable_test',
    );
    Get.put(AuthController(), permanent: true);
    Get.put(RabbitController(), permanent: true);
  });

  final conejo = Rabbit(
    id: '1',
    breed: 'Netherland',
    gender: 'Hembra',
    birthDate: DateTime(2024, 3, 15),
    weightKg: 2.5,
    healthStatus: 'Saludable',
    farmId: 1,
    registrationDate: DateTime(2024, 4, 1),
    chapeta: 'NZ-001',
  );

  List<PesoRegistro> pesajesDeEjemplo() => [
        PesoRegistro(
          id: '1',
          conejoId: 1,
          fecha: DateTime(2024, 4, 1),
          pesoKg: 1.8,
        ),
        PesoRegistro(
          id: '2',
          conejoId: 1,
          fecha: DateTime(2024, 6, 1),
          pesoKg: 2.2,
        ),
        PesoRegistro(
          id: '3',
          conejoId: 1,
          fecha: DateTime(2024, 8, 1),
          pesoKg: 2.6,
        ),
      ];

  testWidgets('el grafico muestra la curva de peso', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RabbitWeightHistorySection(
            rabbit: conejo,
            service: _FakePesoService(pesajesDeEjemplo()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('HISTORIAL DE PESO'), findsOneWidget);
    expect(find.text('3 pesajes'), findsOneWidget);
    expect(find.text('Mín 1.80 kg'), findsOneWidget);
    expect(find.text('Máx 2.60 kg'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'Sin desbordes');

    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('sin historial muestra el estado inicial', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RabbitWeightHistorySection(
            rabbit: conejo,
            service: _FakePesoService(const []),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Peso actual: 2.50 kg'), findsOneWidget);
    expect(
      find.text('Registra al menos dos pesajes para ver la curva de evolución.'),
      findsOneWidget,
    );
    expect(find.byType(LineChart), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('el dialogo de pesaje valida el peso', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RabbitWeightHistorySection(
            rabbit: conejo,
            service: _FakePesoService(const []),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Pesaje'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar peso'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un peso válido'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
  });
}
