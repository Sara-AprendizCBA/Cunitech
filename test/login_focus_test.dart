import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cunitech/screens/auth/login_screen.dart';

FocusNode focusNodeOf(WidgetTester tester, Finder field) {
  final editable = tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
  return editable.focusNode;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://invalid-host-for-tests.invalid',
      publishableKey: 'sb_publishable_test',
    );
  });

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('los campos de texto del login aceptan foco', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pump();
    // La animacion de entrada dura 700 ms: se espera para medir posiciones
    // estables (el Transform.scale inicial desplaza el contenido unos pixeles).
    await tester.pump(const Duration(seconds: 1));

    final emailField = find.byType(TextField).at(0);
    final passwordField = find.byType(TextField).at(1);

    await tester.tap(emailField);
    await tester.pump();
    expect(
      focusNodeOf(tester, emailField).hasFocus,
      isTrue,
      reason: 'El correo debe recibir el foco al hacer clic',
    );

    await tester.tap(passwordField);
    await tester.pump();
    expect(
      focusNodeOf(tester, passwordField).hasFocus,
      isTrue,
      reason: 'La contrasena debe recibir el foco al hacer clic',
    );

    await tester.tap(emailField);
    await tester.pump();
    expect(
      focusNodeOf(tester, emailField).hasFocus,
      isTrue,
      reason: 'Volver al correo debe funcionar',
    );

    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('los campos no se mueven cuando hay error de validacion',
      (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final emailField = find.byType(TextField).at(0);
    final passwordField = find.byType(TextField).at(1);

    final emailBefore = tester.getTopLeft(emailField);
    final passwordBefore = tester.getTopLeft(passwordField);

    // Escribir un correo invalido dispara la validacion en vivo.
    await tester.enterText(emailField, 'correo-invalido');
    await tester.pump();

    expect(find.textContaining('correo'), findsWidgets);
    expect(
      tester.getTopLeft(emailField),
      emailBefore,
      reason: 'El correo no debe moverse al mostrar su error',
    );
    expect(
      tester.getTopLeft(passwordField),
      passwordBefore,
      reason: 'La contrasena no debe moverse al mostrar el error del correo',
    );

    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('los campos siguen respondiendo tras un login fallido',
      (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final emailField = find.byType(TextField).at(0);
    final passwordField = find.byType(TextField).at(1);

    await tester.enterText(emailField, 'usuario@cunitech.com');
    await tester.enterText(passwordField, 'clave123');
    await tester.pump();

    final emailBefore = tester.getTopLeft(emailField);
    final passwordBefore = tester.getTopLeft(passwordField);

    await tester.tap(find.text('INICIAR SESIÓN'));

    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // El intento falla: debe mostrarse el mensaje de error.
    expect(find.textContaining('Revisa'), findsOneWidget);

    expect(
      (tester.getTopLeft(emailField) - emailBefore).distance,
      lessThan(4),
      reason: 'El correo no debe moverse al aparecer el error del formulario',
    );
    expect(
      (tester.getTopLeft(passwordField) - passwordBefore).distance,
      lessThan(4),
      reason: 'La contrasena no debe moverse al aparecer el error',
    );

    await tester.tap(emailField);
    await tester.pump();
    expect(
      focusNodeOf(tester, emailField).hasFocus,
      isTrue,
      reason: 'Tras un fallo, el correo debe poder editarse',
    );

    await tester.tap(passwordField);
    await tester.pump();
    expect(
      focusNodeOf(tester, passwordField).hasFocus,
      isTrue,
      reason: 'Tras un fallo, la contrasena debe poder editarse',
    );

    await tester.pump(const Duration(milliseconds: 10));
  });
}
