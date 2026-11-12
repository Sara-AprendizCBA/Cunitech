import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cunitech/controllers/auth_controller.dart';
import 'package:cunitech/controllers/rabbit_controller.dart';
import 'package:cunitech/core/theme/app_theme.dart';
import 'package:cunitech/models/rabbit.dart';
import 'package:cunitech/screens/rabbits/rabbit_detail_screen.dart';

/// Detecta contenedores con fondo blanco puro dentro de una pantalla en modo
/// oscuro: si el texto usa el color del tema (claro en oscuro), quedaria
/// invisible sobre ese fondo.
List<BoxDecoration> _fondosBlancos(WidgetTester tester) {
  return tester
      .widgetList<Container>(find.byType(Container))
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .where((d) => d.color == Colors.white)
      .toList();
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
    cageNumber: 'J-01',
  );

  testWidgets('el detalle del conejo no deja texto invisible en modo oscuro',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: RabbitDetailScreen(rabbit: conejo),
      ),
    );
    await tester.pump();

    expect(
      _fondosBlancos(tester),
      isEmpty,
      reason: 'Ninguna tarjeta debe quedar con fondo blanco en modo oscuro',
    );
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('en modo claro el detalle usa la superficie del tema',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: RabbitDetailScreen(rabbit: conejo),
      ),
    );
    await tester.pump();

    // En claro tampoco debe haber blanco "duro": usa colorScheme.surface.
    expect(_fondosBlancos(tester), isEmpty);

    await tester.pump(const Duration(milliseconds: 10));
  });
}
