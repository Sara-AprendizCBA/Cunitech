// Smoke test de la pantalla de login.
//
// El test original de la plantilla de Flutter (contador) no aplica a esta app:
// no hay contador y ademas Supabase necesita inicializarse para poder construir
// la pantalla de autenticacion.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cunitech/screens/auth/login_screen.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://invalid-host-for-tests.invalid',
      publishableKey: 'sb_publishable_test',
    );
  });

  testWidgets('la pantalla de login se construye', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pump();

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsWidgets);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
  });
}
