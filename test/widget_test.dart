// ignore_for_file: depend_on_referenced_packages

import 'package:finasangre_app/data/services/ords_client.dart';
import 'package:finasangre_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('muestra el login al iniciar sin sesion guardada', (tester) async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    final client = OrdsClient(
      httpClient: MockClient(
        (_) async => http.Response(
          '{"items":[]}',
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    await tester.pumpWidget(FinaSangreApp(ordsClient: client));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Accede a FINASANGRE'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
