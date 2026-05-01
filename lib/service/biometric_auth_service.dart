import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isSupported() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticate && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({
    required String reason,
    required String title,
    required String cancelButton,
  }) {
    return _localAuth.authenticate(
      localizedReason: reason,
      biometricOnly: true,
      authMessages: <AuthMessages>[
        AndroidAuthMessages(
          signInTitle: title,
          signInHint: '',
          cancelButton: cancelButton,
        ),
        IOSAuthMessages(
          localizedFallbackTitle: title,
          cancelButton: cancelButton,
        ),
      ],
    );
  }

  void stop() {
    try {
      _localAuth.stopAuthentication();
    } catch (_) {
      // Ignore — best-effort cancel.
    }
  }
}
