# FINASANGRE Flutter

1. Crea proyecto Flutter: `flutter create finasangre_app`
2. Copia este `lib`, `assets` y `pubspec.yaml` encima del proyecto.
3. Ejecuta `flutter pub get`.
4. Revisa en `lib/main.dart` la constante `ordsBaseUrl`.
5. Ejecuta `flutter run`.

Login de prueba según inserts SQL:
- Email: admin@finasangre.cl
- Password: 123456

La app consume ORDS directo usando endpoints: caballos_finasangre, herrajes_finasangre, corrales_finasangre, herradores_finasangre, usuarios_finasangre y reportes_mensuales_finasangre.
