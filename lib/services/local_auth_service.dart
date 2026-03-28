import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  static final instance = LocalAuthService._();
  LocalAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  Future<bool> authenticate({String? reason}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason ?? 'Please authenticate to access Task',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }
}
