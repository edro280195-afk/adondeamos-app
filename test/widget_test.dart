import 'package:adondeamos/app/adondeamos_app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('muestra login cuando no hay sesión guardada', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: AdondeamosApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Adondeamos'), findsOneWidget);
    expect(find.text('Bienvenido de vuelta'), findsOneWidget);
    expect(find.text('Entrar'), findsWidgets);
  });
}
