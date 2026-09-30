import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'parties_screen.dart';
import 'results_screen.dart';
import 'statistics_screen.dart';
import 'admin_screen.dart';
import 'identity_verification_screen.dart';
import 'voting_info_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['isAdmin'] == true;
  }

  Widget menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF0D47A1),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text('Wahl-App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () => logout(context),
          ),
        ],
      ),

      body: FutureBuilder<bool>(
        future: isAdmin(),
        builder: (context, snapshot) {
          final admin = snapshot.data == true;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================
                    // WILLKOMMENSBEREICH
                    // =========================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D47A1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.how_to_vote,
                            color: Colors.white,
                            size: 70,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Willkommen zur Wahl-App',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // =========================
                    // MENÜ
                    // =========================
                    const Text(
                      'Menü',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =========================
                    // PARTEIEN
                    // =========================
                    menuCard(
                      icon: Icons.groups,
                      title: 'Parteien',
                      subtitle: 'Informationen und Wahlprogramme ansehen',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PartiesScreen(),
                          ),
                        );
                      },
                    ),

                    // =========================
                    // INFORMATIONEN ZUR WAHL
                    // =========================
                    menuCard(
                      icon: Icons.info_outline,
                      title: 'Informationen zur Wahl',
                      subtitle:
                          'Erststimme, Zweitstimme und Wahlgrundsätze erklärt',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VotingInfoScreen(),
                          ),
                        );
                      },
                    ),

                    // =========================
                    // IDENTITÄTSPRÜFUNG / OCR
                    // =========================
                    menuCard(
                      icon: Icons.badge,
                      title: 'Identität prüfen',
                      subtitle: 'Personalausweis per OCR überprüfen',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const IdentityVerificationScreen(),
                          ),
                        );
                      },
                    ),

                    // =========================
                    // WAHLERGEBNISSE
                    // =========================
                    menuCard(
                      icon: Icons.bar_chart,
                      title: 'Wahlergebnisse',
                      subtitle: 'Aktuelle Stimmenübersicht anzeigen',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ResultsScreen(),
                          ),
                        );
                      },
                    ),

                    // =========================
                    // STATISTIKEN
                    // =========================
                    menuCard(
                      icon: Icons.analytics,
                      title: 'Statistiken',
                      subtitle: 'Prozentwerte und Auswertung ansehen',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatisticsScreen(),
                          ),
                        );
                      },
                    ),

                    // =========================
                    // ADMIN-BEREICH
                    // =========================
                    if (admin)
                      menuCard(
                        icon: Icons.admin_panel_settings,
                        title: 'Admin-Bereich',
                        subtitle: 'Benutzer und System verwalten',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminScreen(),
                            ),
                          );
                        },
                      ),
                  ],
                ), // Column
              ), // SingleChildScrollView
            ), // ConstrainedBox
          ); // Center
        },
      ),
    );
  }
}
