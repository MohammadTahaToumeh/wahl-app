import 'package:flutter/material.dart';

class VotingInfoScreen extends StatelessWidget {
  const VotingInfoScreen({super.key});

  Widget infoCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF0D47A1),
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
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
        title: const Text('Informationen zur Wahl'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wie funktioniert die Bundestagswahl?',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Hier findest du grundlegende und neutral formulierte '
                  'Informationen zum Wahlvorgang.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 25),

                infoCard(
                  icon: Icons.looks_one,
                  title: 'Erststimme',
                  text:
                      'Mit der Erststimme wird eine Person aus dem eigenen '
                      'Wahlkreis gewählt.',
                ),

                infoCard(
                  icon: Icons.looks_two,
                  title: 'Zweitstimme',
                  text:
                      'Mit der Zweitstimme wird die Landesliste einer Partei '
                      'gewählt. Die Zweitstimme ist maßgeblich für die '
                      'Sitzverteilung im Deutschen Bundestag.',
                ),

                infoCard(
                  icon: Icons.lock,
                  title: 'Geheime Wahl',
                  text:
                      'Die Wahl ist geheim. Es soll nicht nachvollziehbar sein, '
                      'wie eine einzelne Person gewählt hat.',
                ),

                infoCard(
                  icon: Icons.balance,
                  title: 'Freie Wahlentscheidung',
                  text:
                      'Die Wahlentscheidung wird von der wählenden Person selbst '
                      'getroffen. Diese App gibt keine Empfehlung für eine '
                      'Partei oder eine Kandidatin beziehungsweise einen Kandidaten.',
                ),

                infoCard(
                  icon: Icons.info_outline,
                  title: 'Hinweis',
                  text:
                      'Diese Seite dient der allgemeinen Information und stellt '
                      'keine Wahlempfehlung dar.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}