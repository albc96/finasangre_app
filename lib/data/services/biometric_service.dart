import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> authenticate() async {
    final supported = await _auth.isDeviceSupported();
    final canCheck = await _auth.canCheckBiometrics;
    if (!supported && !canCheck) return false;
    return _auth.authenticate(
      localizedReason: 'Inicia sesión con huella en FINASANGRE',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  }
}
