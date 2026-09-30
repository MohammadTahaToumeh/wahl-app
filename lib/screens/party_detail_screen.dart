import 'package:flutter/material.dart';
import 'vote_screen.dart';

class PartyDetailScreen extends StatelessWidget {
  final String partyName;
  final String description;
  final String program;

  const PartyDetailScreen({
    super.key,
    required this.partyName,
    required this.description,
    required this.program,
  });

  IconData getPartyIcon(String name) {
    switch (name) {
      case 'CDU':
        return Icons.business;
      case 'SPD':
        return Icons.people;
      case 'Grüne':
        return Icons.eco;
      case 'FDP':
        return Icons.lightbulb;
      case 'AfD':
        return Icons.flag;
      case 'Die Linke':
        return Icons.handshake;
      case 'BSW':
        return Icons.account_balance;
      default:
        return Icons.groups;
    }
  }

  Widget infoCard({
    required String title,
    required String text,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0D47A1)),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: Text(partyName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Icon(
                      getPartyIcon(partyName),
                      color: const Color(0xFF0D47A1),
                      size: 45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    partyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            infoCard(
              title: 'Beschreibung',
              text: description,
              icon: Icons.info,
            ),

            infoCard(
              title: 'Wahlprogramm',
              text: program,
              icon: Icons.article,
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.how_to_vote),
                label: const Text(
                  'Jetzt abstimmen',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VoteScreen(partyName: partyName),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}