import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  Future<Map<String, int>> getResults() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('votes').get();

    final Map<String, int> results = {};

    for (var doc in snapshot.docs) {
      final party = doc.data()['party'];

      if (party != null) {
        results[party] = (results[party] ?? 0) + 1;
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text('Wahlergebnisse'),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: getResults(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final results = snapshot.data!;

          if (results.isEmpty) {
            return const Center(
              child: Text('Noch keine Stimmen vorhanden.'),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: results.entries.map((entry) {
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      title: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Text(
                        '${entry.value} Stimmen',
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}