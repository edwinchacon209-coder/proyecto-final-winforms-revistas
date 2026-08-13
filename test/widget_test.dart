// This is a basic Flutter widget test for Revistas S.A. App.
import 'package:flutter_test/flutter_test.dart';
import 'package:revistas_sa_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Construye la app y verifica que inicia correctamente
    await tester.pumpWidget(const RevistaSAApp());

    // Verifica que el título de la app aparece en la pantalla
    expect(find.text('Revistas S.A.'), findsOneWidget);
  });
}
