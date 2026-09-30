import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth =
      LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final bool deviceSupported =
          await _auth.isDeviceSupported();

      final bool canCheckBiometrics =
          await _auth.canCheckBiometrics;

      // Keine Biometrie verfügbar:
      // Benutzer darf trotzdem fortfahren.
      if (!deviceSupported ||
          !canCheckBiometrics) {
        return true;
      }

      final List<BiometricType>
          availableBiometrics =
          await _auth.getAvailableBiometrics();

      // Keine biometrischen Daten eingerichtet.
      if (availableBiometrics.isEmpty) {
        return true;
      }

      final bool authenticated =
          await _auth.authenticate(
        localizedReason:
            'Bitte bestätige deine Identität, um fortzufahren.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      return authenticated;
    } on LocalAuthException {
      return false;
    } catch (e) {
      return false;
    }
  }
}