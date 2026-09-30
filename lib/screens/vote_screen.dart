import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/biometric_service.dart';

class VoteScreen extends StatelessWidget {
  final String partyName;

  const VoteScreen({
    super.key,
    required this.partyName,
  });

  Future<void> vote(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Du bist nicht angemeldet.',
          ),
        ),
      );
      return;
    }

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      // =========================
      // BENUTZERSTATUS PRÜFEN
      // =========================

      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Benutzerkonto wurde nicht gefunden.',
            ),
          ),
        );
        return;
      }

      final data = snapshot.data();

      if (data?['blocked'] == true) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dein Konto wurde gesperrt. Du darfst nicht abstimmen.',
            ),
          ),
        );
        return;
      }

      if (data?['isVerified'] != true) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dein Konto wurde noch nicht verifiziert.',
            ),
          ),
        );
        return;
      }

      if (data?['hasVoted'] == true) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Du hast bereits abgestimmt.',
            ),
          ),
        );
        return;
      }

      // =========================
      // BIOMETRISCHE BESTÄTIGUNG
      // =========================

      final biometricService =
          BiometricService();

      final bool biometricSuccess =
          await biometricService.authenticate();

      if (!biometricSuccess) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometrische Bestätigung fehlgeschlagen.',
            ),
          ),
        );
        return;
      }

      // =========================
      // STIMME SPEICHERN
      // =========================

      final voteDoc =
          FirebaseFirestore.instance.collection('votes').doc();

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final freshSnapshot =
              await transaction.get(userDoc);

          final freshData =
              freshSnapshot.data();

          if (freshData?['blocked'] == true ||
              freshData?['isVerified'] != true ||
              freshData?['hasVoted'] == true) {
            throw StateError(
              'ABSTIMMUNG_NICHT_ERLAUBT',
            );
          }

          // Stimme ohne Benutzer-ID oder E-Mail speichern.
          transaction.set(
            voteDoc,
            {
              'party': partyName,
              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );

          // Benutzer als bereits abgestimmt markieren.
          transaction.update(
            userDoc,
            {
              'hasVoted': true,
            },
          );
        },
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Du hast für $partyName abgestimmt ✅',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      if (e
          .toString()
          .contains('ABSTIMMUNG_NICHT_ERLAUBT')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Du hast bereits abgestimmt oder darfst nicht abstimmen.',
            ),
          ),
        );
        return;
      }

      debugPrint(
        'Fehler bei der Abstimmung: $e',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bei der Abstimmung ist ein Fehler aufgetreten.',
          ),
        ),
      );
    }
  }

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
      backgroundColor:
          const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0D47A1),
        foregroundColor:
            Colors.white,
        title:
            const Text(
          'Abstimmung bestätigen',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Center(
          child: Card(
            elevation: 5,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                24,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor:
                        const Color(
                      0xFF0D47A1,
                    ),
                    child: Icon(
                      getPartyIcon(
                        partyName,
                      ),
                      color:
                          Colors.white,
                      size: 45,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  const Text(
                    'Stimme abgeben',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    'Möchtest du wirklich für $partyName abstimmen?',
                    style:
                        const TextStyle(
                      fontSize: 18,
                      height: 1.4,
                    ),
                    textAlign:
                        TextAlign.center,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFFFF3CD,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                    child:
                        const Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color:
                              Colors.orange,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            'Hinweis: Deine Stimme kann danach nicht mehr geändert werden.',
                            style:
                                TextStyle(
                              fontSize:
                                  14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    height: 55,
                    child:
                        ElevatedButton.icon(
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF0D47A1,
                        ),
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                      ),
                      icon:
                          const Icon(
                        Icons.how_to_vote,
                      ),
                      label:
                          const Text(
                        'Stimme verbindlich abgeben',
                        style:
                            TextStyle(
                          fontSize: 17,
                        ),
                      ),
                      onPressed: () =>
                          vote(context),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextButton(
                    onPressed: () =>
                        Navigator.pop(
                      context,
                    ),
                    child:
                        const Text(
                      'Abbrechen',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}