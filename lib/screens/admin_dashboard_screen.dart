import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<Map<String, dynamic>> getDashboardData() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    final votesSnapshot =
        await FirebaseFirestore.instance.collection('votes').get();

    final partiesSnapshot =
        await FirebaseFirestore.instance.collection('parties').get();

    final Map<String, int> voteCount = {};

    for (var doc in votesSnapshot.docs) {
      final party = doc.data()['party'];

      if (party != null) {
        voteCount[party] = (voteCount[party] ?? 0) + 1;
      }
    }

    String winner = 'Noch keine Stimmen';
    int maxVotes = 0;

    voteCount.forEach((party, count) {
      if (count > maxVotes) {
        maxVotes = count;
        winner = party;
      }
    });

    return {
      'users': usersSnapshot.docs.length,
      'votes': votesSnapshot.docs.length,
      'parties': partiesSnapshot.docs.length,
      'winner': winner,
    };
  }

  Widget dashboardCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, size: 35),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getDashboardData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                dashboardCard('Benutzer', data['users'].toString(), Icons.people),
                dashboardCard('Stimmen', data['votes'].toString(), Icons.how_to_vote),
                dashboardCard('Parteien', data['parties'].toString(), Icons.groups),
                dashboardCard('Aktuell vorne', data['winner'].toString(), Icons.emoji_events),
              ],
            ),
          );
        },
      ),
    );
  }
}