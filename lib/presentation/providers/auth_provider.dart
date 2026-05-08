import "dart:async";
import "dart:convert";

import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../core/config/app_config.dart";
import "../../data/models/suscripcion_model.dart";
import "../../data/models/usuario_model.dart";
import "../../data/services/audit_service.dart";
import "../../data/services/biometric_service.dart";
import "../../data/services/ords_client.dart";

class AuthProvider extends ChangeNotifier {
  final OrdsClient client;
  final BiometricService biometricService;
  final AuditService auditService;

  AuthProvider(this.client, this.biometricService, this.auditService);

  bool loading = true;
  String? error;
  UsuarioModel? user;
  SuscripcionModel? suscripcion;

  bool get loggedIn => user != null;
  bool get blocked =>
      user?.isHerrador == true &&
      (suscripcion == null
          ? DateTime.now().day > 7
          : _subscriptionState(suscripcion!) == "BLOQUEADA");

  Future<void> restore() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      final raw = prefs.getString("session_user");
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw);
          user = decoded is Map
              ? UsuarioModel.fromJson(Map<String, dynamic>.from(decoded))
              : null;
          if (user != null) {
            await _loadSubscription()
                .timeout(const Duration(seconds: 8));
          }
        } catch (_) {
          await prefs.remove("session_user");
          user = null;
          suscripcion = null;
        }
      }
    } on TimeoutException catch (_) {
      user = null;
      suscripcion = null;
      error = "Tiempo de espera agotado. Verifica tu conexion.";
    } catch (_) {
      user = null;
      suscripcion = null;
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> login(
      {required String email,
      required String password,
      required bool remember}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final login = email.toLowerCase().trim();
      final loginClient = OrdsClient(baseUrl: AppConfig.ordsRootUrl);
      final users = await loginClient
          .getList(OrdsEndpoints.usuariosLogin)
          .timeout(const Duration(seconds: 10));
      final found = users
          .map(UsuarioModel.fromJson)
          .where((u) => u.email.toLowerCase().trim() == login)
          .cast<UsuarioModel?>()
          .firstWhere((u) => u != null, orElse: () => null);
      if (found == null) throw Exception("Usuario no encontrado");
      if (found.activo != "SI") throw Exception("Usuario inactivo");
      if (found.passwordHash != password) {
        throw Exception("Contrasena incorrecta");
      }
      user = found;
      await _loadSubscription();
      final prefs = await SharedPreferences.getInstance();
      if (remember) {
        await prefs.setString("session_user", jsonEncode(found.toJson()));
      } else {
        await prefs.remove("session_user");
      }
      await auditService.record(
        action: "login",
        module: "AUTH",
        detail: found.email,
        userId: found.idUsuario,
      );
      loading = false;
      notifyListeners();
      return true;
    } on TimeoutException catch (_) {
      error =
          "Error de conexion o servidor no responde. Por favor, revisa tu internet e intenta nuevamente.";
      loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = _cleanLoginError(e);
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> biometricLogin() async {
    error = null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("session_user");
    if (raw == null) {
      error = "No hay sesion guardada para usar huella.";
      notifyListeners();
      return false;
    }
    final ok = await biometricService.authenticate();
    if (!ok) return false;
    try {
      user = UsuarioModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      await _loadSubscription();
      notifyListeners();
      return true;
    } catch (_) {
      await prefs.remove("session_user");
      error = "La sesion guardada no es valida. Ingresa con clave.";
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final current = user;
    user = null;
    suscripcion = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("session_user");
    await auditService.record(
      action: "logout",
      module: "AUTH",
      detail: current?.email,
      userId: current?.idUsuario,
    );
    notifyListeners();
  }

  Future<void> _loadSubscription() async {
    suscripcion = null;
    if (user == null) return;
    if (user!.isOwnerOrAdmin) return;
    final now = DateTime.now();
    try {
      final rows = await client
          .getList(OrdsEndpoints.suscripciones)
          .timeout(const Duration(seconds: 10));
      final matches = rows.map(SuscripcionModel.fromJson).where((s) =>
          s.idUsuario == user!.idUsuario &&
          s.mes == now.month &&
          s.anio == now.year);
      suscripcion = matches.isEmpty ? null : matches.first;
    } on TimeoutException catch (_) {
      suscripcion = null;
    } on OrdsException {
      suscripcion = null;
    }
  }

  String _subscriptionState(SuscripcionModel sub) {
    if (sub.pagado || sub.estado == "PAGADA") return "PAGADA";
    if (DateTime.now().day <= 7) return "GRACIA";
    return "BLOQUEADA";
  }

  String _cleanLoginError(Object e) {
    final text = e.toString();
    if (text.contains("<!DOCTYPE") ||
        text.contains("<html") ||
        text.contains("ORDS")) {
      return "No se pudo conectar con ORDS. Revisa endpoint o conexion.";
    }
    return text.replaceFirst("Exception: ", "");
  }
}
