import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> updateBlockedStatus(
    String userId,
    bool value,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'blocked': value,
    });
  }

  Future<void> updateAdminStatus(
    String userId,
    bool value,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'isAdmin': value,
    });
  }

  Future<void> updateVerifiedStatus(
    String userId,
    bool value,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'isVerified': value,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text('Admin Bereich'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.dashboard),
                label: const Text('Dashboard öffnen'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AdminDashboardScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Fehler beim Laden der Benutzer',
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data()
                        as Map<String, dynamic>;

                    final userId = users[index].id;

                    final isBlocked =
                        user['blocked'] == true;

                    final isAdmin =
                        user['isAdmin'] == true;

                    final isVerified =
                        user['isVerified'] == true;

                    final hasVoted =
                        user['hasVoted'] == true;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                isAdmin
                                    ? Icons
                                        .admin_panel_settings
                                    : Icons.person,
                                color: const Color(
                                  0xFF0D47A1,
                                ),
                              ),
                              title: Text(
                                user['email'] ?? '',
                              ),
                              subtitle: Text(
                                hasVoted
                                    ? 'Hat abgestimmt'
                                    : 'Hat noch nicht abgestimmt',
                              ),
                            ),

                            SwitchListTile(
                              title:
                                  const Text('Verifiziert'),
                              subtitle: const Text(
                                'Nutzer darf geschützte Funktionen verwenden',
                              ),
                              value: isVerified,
                              onChanged: (value) async {
                                await updateVerifiedStatus(
                                  userId,
                                  value,
                                );
                              },
                            ),

                            SwitchListTile(
                              title:
                                  const Text('Gesperrt'),
                              subtitle: const Text(
                                'Nutzer darf nicht mehr abstimmen',
                              ),
                              value: isBlocked,
                              onChanged: (value) async {
                                await updateBlockedStatus(
                                  userId,
                                  value,
                                );
                              },
                            ),

                            SwitchListTile(
                              title:
                                  const Text('Admin'),
                              subtitle: const Text(
                                'Nutzer hat Admin-Rechte',
                              ),
                              value: isAdmin,
                              onChanged: (value) async {
                                await updateAdminStatus(
                                  userId,
                                  value,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}