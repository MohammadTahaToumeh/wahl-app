import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'party_detail_screen.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  String searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text('Parteien'),
      ),
      body: Column(
        children: [
          // Suchfeld
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Partei suchen...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase().trim();
                    });
                  },
                ),
              ),
            ),
          ),

          // Parteienliste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('parties').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Fehler beim Laden der Parteien'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final parties = snapshot.data!.docs.where((doc) {
                  final party = doc.data() as Map<String, dynamic>;

                  final name =
                      (party['name'] ?? '').toString().toLowerCase();

                  final description =
                      (party['description'] ?? '').toString().toLowerCase();

                  return name.contains(searchQuery) ||
                      description.contains(searchQuery);
                }).toList();

                if (parties.isEmpty) {
                  return const Center(
                    child: Text(
                      'Keine Partei gefunden.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: parties.length,
                      itemBuilder: (context, index) {
                        final party =
                            parties[index].data() as Map<String, dynamic>;

                        final name = party['name'] ?? '';
                        final description = party['description'] ?? '';

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(18),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFF0D47A1),
                              child: Icon(
                                getPartyIcon(name),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PartyDetailScreen(
                                    partyName: name,
                                    description: description,
                                    program: party['program'] ?? '',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}