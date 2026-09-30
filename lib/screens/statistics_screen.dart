import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

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
        title: const Text('Statistiken'),
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
          final totalVotes =
              results.values.fold<int>(0, (sum, value) => sum + value);

          if (totalVotes == 0) {
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
                  final percent = (entry.value / totalVotes) * 100;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${entry.value} Stimmen '
                            '(${percent.toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
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