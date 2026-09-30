import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  Future<void> sendVerificationEmail(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      print("USER: ${user?.email}");
      print("VERIFIED: ${user?.emailVerified}");

      await user?.sendEmailVerification();

      print("EMAIL GESENDET");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bestätigungs-E-Mail wurde gesendet.'),
        ),
      );
    } catch (e) {
      print("FEHLER: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> checkVerification(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await user?.reload();

      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-Mail erfolgreich bestätigt ✅'),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-Mail wurde noch nicht bestätigt.'),
          ),
        );
      }
    } catch (e) {
      print("FEHLER: $e");
    }
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Mail bestätigen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.email, size: 100),
            const SizedBox(height: 20),

            const Text(
              'Bitte bestätige deine E-Mail-Adresse.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(user?.email ?? ''),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => sendVerificationEmail(context),
              child: const Text('Bestätigungs-E-Mail senden'),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () => checkVerification(context),
              child: const Text('Ich habe bestätigt'),
            ),
          ],
        ),
      ),
    );
  }
}