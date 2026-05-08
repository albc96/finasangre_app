# FINASANGRE

FINASANGRE es una aplicacion Flutter para administrar el control de herrajes de caballos, corrales, herradores, preparadores, usuarios y reportes operativos.

La aplicacion esta pensada para uso diario en terreno y oficina: permite registrar informacion, mantener historial, revisar alertas, generar reportes y sincronizar datos con Oracle Cloud mediante ORDS.

## Funciones principales

- Login de usuarios con roles y control de acceso.
- Dashboard operativo con resumen de caballos, herrajes, corrales, herradores y suscripciones.
- CRUD de caballos, herrajes, corrales, herradores, preparadores y usuarios.
- Registro de herrajes con caballo, herrador, corral, fecha, hora, tipo y observaciones.
- Alertas de caballos con herrajes pendientes.
- Reportes mensuales y detalle de reportes.
- Exportacion y envio de reportes por PDF, WhatsApp y correo.
- Asistente AURA para consultas rapidas dentro de la aplicacion.
- Cache local y sincronizacion de datos pendientes cuando vuelve la conexion.
- Soporte Android, Web, Windows, Linux, macOS e iOS desde el mismo proyecto Flutter.

## Conexion en la nube

FINASANGRE guarda y consulta informacion en Oracle Cloud usando ORDS.

Los detalles internos de conexion y endpoints no se documentan publicamente en este README por seguridad.

## Requisitos

- Flutter estable instalado.
- Android Studio o SDK Android para compilar APK.
- Conexion a internet para sincronizar con la nube.

## Comandos utiles

Instalar dependencias:

```bash
flutter pub get
```

Revisar errores:

```bash
flutter analyze
```

Ejecutar pruebas:

```bash
flutter test
```

Ejecutar la aplicacion:

```bash
flutter run
```

Generar APK Android:

```bash
flutter build apk --release
```

El APK queda en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Estado actual

- Analisis Flutter sin errores.
- Tests automatizados pasando.
- APK release generado correctamente.
- Repositorio preparado para control de versiones en GitHub.
