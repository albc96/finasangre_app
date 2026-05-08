import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/repositories/caballo_repository.dart';
import '../../data/repositories/herraje_repository.dart';

class NotificationService {
  static const _channelId = 'finasangre_alerts';
  static const _channelName = 'FINASANGRE Alertas';
  static const _channelDesc = 'Notificaciones de caballos sin herraje';
  static const _prefsKey = 'last_notified_';

  final CaballoRepository caballos;
  final HerrajeRepository herrajes;
  final FlutterLocalNotificationsPlugin _notifs = FlutterLocalNotificationsPlugin();

  NotificationService({
    required this.caballos,
    required this.herrajes,
  });

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifs.initialize(settings);
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }
  }

  Future<void> _requestAndroidPermissions() async {
    final android = _notifs.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> checkAndNotify({
    int alertFromDays = 25,
    int criticalDays = 30,
  }) async {
    try {
      final caballosList = await caballos.list().timeout(const Duration(seconds: 15));
      final herrajesList = await herrajes.list().timeout(const Duration(seconds: 15));
      final prefs = await SharedPreferences.getInstance();

      for (final caballo in caballosList) {
        if (caballo.activo.toUpperCase() != 'SI') continue;

        final caballoHerrajes = herrajesList
            .where((h) => h.idCaballo == caballo.idCaballo)
            .toList()
          ..sort((a, b) {
            final da = a.fechaHerraje ?? DateTime(2000);
            final db = b.fechaHerraje ?? DateTime(2000);
            return db.compareTo(da);
          });

        final lastDate = caballoHerrajes.isNotEmpty
            ? (caballoHerrajes.first.fechaHerraje ?? DateTime(2000))
            : DateTime(2000);
        final daysSince = DateTime.now().difference(lastDate).inDays;

        if (daysSince >= alertFromDays && daysSince <= criticalDays) {
          final lastNotified = prefs.getInt('$_prefsKey${caballo.idCaballo}') ?? 0;
          if (lastNotified != daysSince) {
            await _notify(caballo.nombreCaballo, daysSince);
            await prefs.setInt('$_prefsKey${caballo.idCaballo}', daysSince);
          }
        } else if (daysSince < alertFromDays) {
          await prefs.remove('$_prefsKey${caballo.idCaballo}');
        }
      }
    } catch (_) {
      // Silently fail - network issues shouldn't crash the app
    }
  }

  Future<void> _notify(String nombreCaballo, int dias) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF00E5FF),
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifs.show(
      nombreCaballo.hashCode,
      'FINASANGRE AURA',
      'El caballo $nombreCaballo lleva $dias días sin herraje.',
      details,
    );
  }

  Future<void> clearNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefsKey));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
