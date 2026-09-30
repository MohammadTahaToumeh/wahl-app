import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../services/auth_token_service.dart';
import 'liveness_screen.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  Uint8List? _selfieBytes;

  String? _surname;
  String? _forename;
  String? _dateOfBirth;
  String? _nationality;

  String _rawText = '';

  bool _isLoading = false;
  bool _ocrSuccessful = false;

  bool _isFaceChecking = false;
  bool? _faceMatch;
  double? _similarity;

  // =========================================================
  // FIREBASE TOKEN
  // =========================================================

  Future<String> _getToken() async {
    final token = await AuthTokenService.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Benutzer ist nicht angemeldet.',
      );
    }

    return token;
  }

  // =========================================================
  // AUSWEISBILD AUSWÄHLEN
  // =========================================================

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    if (!mounted) return;

    setState(() {
      _imageBytes = bytes;

      _surname = null;
      _forename = null;
      _dateOfBirth = null;
      _nationality = null;

      _rawText = '';
      _ocrSuccessful = false;

      _faceMatch = null;
      _similarity = null;
      _selfieBytes = null;
    });
  }

  // =========================================================
  // SELFIE AUFNEHMEN
  // =========================================================

  Future<void> takeSelfie() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    if (!mounted) return;

    setState(() {
      _selfieBytes = bytes;
      _faceMatch = null;
      _similarity = null;
    });
  }

  // =========================================================
  // OCR
  // =========================================================

  Future<void> sendImageToOcr() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte zuerst ein Ausweisbild auswählen.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _ocrSuccessful = false;
    });

    try {
      final token = await _getToken();

      final uri = Uri.parse(
        'http://127.0.0.1:5000/ocr',
      );

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      // Firebase ID Token an Backend senden.
      request.headers['Authorization'] =
          'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _imageBytes!,
          filename: 'ausweis.jpg',
        ),
      );

      final response = await request.send();

      final responseBody =
          await response.stream.bytesToString();

      final Map<String, dynamic> result =
          jsonDecode(responseBody);

      if (response.statusCode == 200 &&
          result['success'] == true) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(
          result['data'] ?? {},
        );

        if (!mounted) return;

        setState(() {
          _surname =
              data['surname']?.toString();

          _forename =
              data['forename']?.toString();

          _dateOfBirth =
              data['dateOfBirth']?.toString();

          _nationality =
              data['nationality']?.toString();

          _rawText =
              result['rawText']?.toString() ?? '';

          _ocrSuccessful =
              result['verificationPassed'] == true;
        });

        if (_ocrSuccessful) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'OCR-Erkennung erfolgreich.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Das Ausweisdokument konnte nicht vollständig erkannt werden.',
              ),
            ),
          );
        }
      } else {
        throw Exception(
          result['message'] ??
              'OCR-Erkennung fehlgeschlagen.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fehler bei der OCR-Erkennung: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // GESICHT VERGLEICHEN
  // =========================================================

  Future<void> verifyFace() async {
    if (!_ocrSuccessful) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte zuerst die OCR-Prüfung erfolgreich abschließen.',
          ),
        ),
      );
      return;
    }

    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte zuerst ein Ausweisbild auswählen.',
          ),
        ),
      );
      return;
    }

    if (_selfieBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte zuerst ein Selfie aufnehmen.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isFaceChecking = true;
      _faceMatch = null;
      _similarity = null;
    });

    try {
      final token = await _getToken();

      final uri = Uri.parse(
        'http://127.0.0.1:5000/face-verify',
      );

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      // Firebase ID Token an Backend senden.
      request.headers['Authorization'] =
          'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes(
          'documentImage',
          _imageBytes!,
          filename: 'ausweis.jpg',
        ),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'selfieImage',
          _selfieBytes!,
          filename: 'selfie.jpg',
        ),
      );

      final response = await request.send();

      final responseBody =
          await response.stream.bytesToString();

      final Map<String, dynamic> result =
          jsonDecode(responseBody);

      if (response.statusCode == 200 &&
          result['success'] == true) {
        if (!mounted) return;

        setState(() {
          _faceMatch =
              result['faceMatch'] == true;

          final value = result['similarity'];

          if (value is num) {
            _similarity = value.toDouble();
          }
        });

        if (_faceMatch == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gesichtsvergleich erfolgreich.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Die Gesichter stimmen nicht überein.',
              ),
            ),
          );
        }
      } else {
        throw Exception(
          result['message'] ??
              'Gesichtsvergleich fehlgeschlagen.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fehler beim Gesichtsvergleich: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFaceChecking = false;
        });
      }
    }
  }

  // =========================================================
  // DATENZEILE
  // =========================================================

  Widget dataRow(
    String title,
    String? value,
  ) {
    final displayValue =
        value == null || value.trim().isEmpty
            ? 'Nicht erkannt'
            : value;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(displayValue),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text(
          'Identitätsprüfung',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.badge,
              size: 80,
              color: Color(0xFF0D47A1),
            ),

            const SizedBox(height: 20),

            const Text(
              'Personalausweis prüfen',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Wähle ein Bild deines Ausweisdokuments aus. '
              'Die relevanten Daten werden automatisch erkannt.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),

            // ===============================================
            // AUSWEISVORSCHAU
            // ===============================================

            if (_imageBytes != null)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(16),
                child: Image.memory(
                  _imageBytes!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Noch kein Bild ausgewählt',
                  ),
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    _isLoading ? null : pickImage,
                icon: const Icon(
                  Icons.photo_library,
                ),
                label: const Text(
                  'Ausweisbild auswählen',
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    _isLoading
                        ? null
                        : sendImageToOcr,
                icon: const Icon(
                  Icons.document_scanner,
                ),
                label: Text(
                  _isLoading
                      ? 'OCR läuft...'
                      : 'Ausweis prüfen',
                ),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 25),
              const CircularProgressIndicator(),
            ],

            // ===============================================
            // OCR ERGEBNIS
            // ===============================================

            if (_ocrSuccessful) ...[
              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons
                              .verified_user_outlined,
                          color:
                              Color(0xFF0D47A1),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Erkannte Daten',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 30),

                    dataRow(
                      'Nachname:',
                      _surname,
                    ),

                    dataRow(
                      'Vorname:',
                      _forename,
                    ),

                    dataRow(
                      'Geburtsdatum:',
                      _dateOfBirth,
                    ),

                    dataRow(
                      'Nationalität:',
                      _nationality,
                    ),
                  ],
                ),
              ),

              if (_rawText.isNotEmpty) ...[
                const SizedBox(height: 20),

                ExpansionTile(
                  title: const Text(
                    'OCR-Rohtext anzeigen',
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      child: SelectableText(
                        _rawText,
                      ),
                    ),
                  ],
                ),
              ],

              // =============================================
              // SELFIE
              // =============================================

              const SizedBox(height: 30),

              const Divider(),

              const SizedBox(height: 20),

              const Icon(
                Icons.face,
                size: 60,
                color: Color(0xFF0D47A1),
              ),

              const SizedBox(height: 12),

              const Text(
                'Selfie aufnehmen',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Nimm ein Selfie auf. Das Gesicht wird '
                'mit dem Foto auf dem Ausweisdokument verglichen.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              if (_selfieBytes != null)
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(16),
                  child: Image.memory(
                    _selfieBytes!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                )
              else
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    border: Border.all(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Noch kein Selfie aufgenommen',
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: takeSelfie,
                  icon: const Icon(
                    Icons.camera_alt,
                  ),
                  label: const Text(
                    'Selfie aufnehmen',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                      _isFaceChecking
                          ? null
                          : verifyFace,
                  icon: const Icon(
                    Icons
                        .face_retouching_natural,
                  ),
                  label: Text(
                    _isFaceChecking
                        ? 'Gesichter werden verglichen...'
                        : 'Gesichter vergleichen',
                  ),
                ),
              ),

              if (_isFaceChecking) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],

              // =============================================
              // FACE ERGEBNIS
              // =============================================

              if (_faceMatch != null) ...[
                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _faceMatch == true
                        ? const Color(
                            0xFFE8F5E9,
                          )
                        : const Color(
                            0xFFFFEBEE,
                          ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _faceMatch == true
                            ? Icons.verified
                            : Icons
                                .error_outline,
                        size: 45,
                        color:
                            _faceMatch == true
                                ? Colors.green
                                : Colors.red,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        _faceMatch == true
                            ? 'Gesicht erfolgreich bestätigt'
                            : 'Gesichter stimmen nicht überein',
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      if (_similarity !=
                          null) ...[
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          'Ähnlichkeitswert: '
                          '${_similarity!.toStringAsFixed(3)}',
                        ),
                      ],
                    ],
                  ),
                ),

                // ===========================================
                // LIVENESS
                // ===========================================

                if (_faceMatch == true) ...[
                  const SizedBox(
                    height: 20,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    height: 52,
                    child:
                        ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const LivenessScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.security,
                      ),
                      label: const Text(
                        'Liveness-Prüfung starten',
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}