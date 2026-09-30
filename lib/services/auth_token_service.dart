import 'package:firebase_auth/firebase_auth.dart';

class AuthTokenService {
  static Future<String?> getIdToken() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return await user.getIdToken();
  }
}