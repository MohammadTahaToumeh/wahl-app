import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_token_service.dart';

class LivenessScreen extends StatefulWidget {
  const LivenessScreen({super.key});

  @override
  State<LivenessScreen> createState() =>
      _LivenessScreenState();
}

class _LivenessScreenState
    extends State<LivenessScreen> {
  CameraController? _cameraController;

  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isChecking = false;

  int _currentStep = 0;

  Uint8List? _frontImage;
  Uint8List? _leftImage;
  Uint8List? _rightImage;

  bool? _livenessPassed;

  double? _frontValue;
  double? _leftValue;
  double? _rightValue;

  double? _leftMovement;
  double? _rightMovement;

  final List<String> _instructions = [
    'Bitte gerade in die Kamera schauen.',
    'Bitte den Kopf nach links drehen.',
    'Bitte den Kopf nach rechts drehen.',
  ];

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

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
  // KAMERA INITIALISIEREN
  // =========================================================

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception(
          'Keine Kamera wurde gefunden.',
        );
      }

      CameraDescription selectedCamera =
          cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection ==
            CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kamera konnte nicht gestartet werden: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // AUFNAHME ERSTELLEN
  // =========================================================

  Future<void> captureStep() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _livenessPassed = null;
    });

    try {
      final XFile image =
          await controller.takePicture();

      final Uint8List bytes =
          await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        if (_currentStep == 0) {
          _frontImage = bytes;
        } else if (_currentStep == 1) {
          _leftImage = bytes;
        } else if (_currentStep == 2) {
          _rightImage = bytes;
        }

        if (_currentStep < 2) {
          _currentStep++;
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aufnahme fehlgeschlagen: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  bool get allImagesCaptured {
    return _frontImage != null &&
        _leftImage != null &&
        _rightImage != null;
  }

  // =========================================================
  // LIVENESS SERVERSEITIG PRÜFEN
  // =========================================================

  Future<void> verifyLiveness() async {
    if (!allImagesCaptured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte zuerst alle drei Aufnahmen erstellen.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _livenessPassed = null;
    });

    try {
      final token = await _getToken();

      final uri = Uri.parse(
        'http://127.0.0.1:5000/liveness-verify',
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
          'frontImage',
          _frontImage!,
          filename: 'front.jpg',
        ),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'leftImage',
          _leftImage!,
          filename: 'left.jpg',
        ),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'rightImage',
          _rightImage!,
          filename: 'right.jpg',
        ),
      );

      final response = await request.send();

      final responseBody =
          await response.stream.bytesToString();

      final Map<String, dynamic> result =
          jsonDecode(responseBody);

      if (response.statusCode == 200 &&
          result['success'] == true) {
        final values =
            Map<String, dynamic>.from(
          result['values'] ?? {},
        );

        final movement =
            Map<String, dynamic>.from(
          result['movement'] ?? {},
        );

        if (!mounted) return;

        setState(() {
          _livenessPassed =
              result['livenessPassed'] == true;

          _frontValue =
              (values['front'] as num?)
                  ?.toDouble();

          _leftValue =
              (values['left'] as num?)
                  ?.toDouble();

          _rightValue =
              (values['right'] as num?)
                  ?.toDouble();

          _leftMovement =
              (movement['left'] as num?)
                  ?.toDouble();

          _rightMovement =
              (movement['right'] as num?)
                  ?.toDouble();
        });

        if (_livenessPassed == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Liveness-Prüfung erfolgreich. Benutzer wurde verifiziert.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Liveness-Prüfung nicht bestanden.',
              ),
            ),
          );
        }
      } else {
        throw Exception(
          result['message'] ??
              'Liveness-Prüfung fehlgeschlagen.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fehler bei der Liveness-Prüfung: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  // =========================================================
  // PRÜFUNG ZURÜCKSETZEN
  // =========================================================

  void resetLiveness() {
    setState(() {
      _currentStep = 0;

      _frontImage = null;
      _leftImage = null;
      _rightImage = null;

      _livenessPassed = null;

      _frontValue = null;
      _leftValue = null;
      _rightValue = null;

      _leftMovement = null;
      _rightMovement = null;
    });
  }

  // =========================================================
  // SCHRITTANZEIGE
  // =========================================================

  Widget buildStep(
    int index,
    String title,
  ) {
    final bool completed =
        (index == 0 && _frontImage != null) ||
        (index == 1 && _leftImage != null) ||
        (index == 2 && _rightImage != null);

    final bool active =
        _currentStep == index && !completed;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: completed
              ? Colors.green
              : active
                  ? const Color(0xFF0D47A1)
                  : Colors.grey.shade300,
          child: Icon(
            completed
                ? Icons.check
                : Icons.circle,
            size: completed ? 20 : 10,
            color: completed || active
                ? Colors.white
                : Colors.grey,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: active
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
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
          'Liveness-Prüfung',
        ),
      ),

      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _cameraController == null ||
                  !_cameraController!
                      .value.isInitialized
              ? const Center(
                  child: Text(
                    'Kamera ist nicht verfügbar.',
                  ),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      const Icon(
                        Icons
                            .face_retouching_natural,
                        size: 70,
                        color:
                            Color(0xFF0D47A1),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Lebendigkeit prüfen',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Führe die angezeigten Bewegungen vor der Kamera aus.',
                        textAlign:
                            TextAlign.center,
                      ),

                      const SizedBox(height: 25),

                      // =====================================
                      // KAMERA
                      // =====================================

                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                        child: AspectRatio(
                          aspectRatio:
                              _cameraController!
                                  .value
                                  .aspectRatio,
                          child: CameraPreview(
                            _cameraController!,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // =====================================
                      // SCHRITTE
                      // =====================================

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(
                          18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: Column(
                          children: [
                            buildStep(
                              0,
                              'Geradeaus schauen',
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            buildStep(
                              1,
                              'Kopf nach links drehen',
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            buildStep(
                              2,
                              'Kopf nach rechts drehen',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // =====================================
                      // AKTUELLE ANWEISUNG
                      // =====================================

                      if (!allImagesCaptured)
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(
                            15,
                          ),
                          decoration:
                              BoxDecoration(
                            color: const Color(
                              0xFFE3F2FD,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                          child: Text(
                            _instructions[
                                _currentStep],
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 15),

                      // =====================================
                      // AUFNAHME
                      // =====================================

                      if (!allImagesCaptured)
                        SizedBox(
                          width:
                              double.infinity,
                          height: 52,
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                _isCapturing
                                    ? null
                                    : captureStep,
                            icon: const Icon(
                              Icons.camera_alt,
                            ),
                            label: Text(
                              _isCapturing
                                  ? 'Aufnahme läuft...'
                                  : 'Aufnahme',
                            ),
                          ),
                        ),

                      // =====================================
                      // ALLE BILDER ERSTELLT
                      // =====================================

                      if (allImagesCaptured) ...[
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),
                          decoration:
                              BoxDecoration(
                            color: const Color(
                              0xFFE8F5E9,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color:
                                    Colors.green,
                              ),

                              SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child: Text(
                                  'Alle Aufnahmen wurden erstellt.',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          height: 52,
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                _isChecking
                                    ? null
                                    : verifyLiveness,
                            icon: const Icon(
                              Icons.security,
                            ),
                            label: Text(
                              _isChecking
                                  ? 'Prüfung läuft...'
                                  : 'Liveness prüfen',
                            ),
                          ),
                        ),

                        if (_isChecking) ...[
                          const SizedBox(
                            height: 20,
                          ),
                          const CircularProgressIndicator(),
                        ],

                        // ===================================
                        // ERGEBNIS
                        // ===================================

                        if (_livenessPassed !=
                            null) ...[
                          const SizedBox(
                            height: 20,
                          ),

                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets.all(
                              18,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  _livenessPassed ==
                                          true
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
                                  _livenessPassed ==
                                          true
                                      ? Icons
                                          .verified
                                      : Icons
                                          .error_outline,
                                  size: 45,
                                  color:
                                      _livenessPassed ==
                                              true
                                          ? Colors.green
                                          : Colors.red,
                                ),

                                const SizedBox(
                                  height: 10,
                                ),

                                Text(
                                  _livenessPassed ==
                                          true
                                      ? 'Liveness erfolgreich bestätigt'
                                      : 'Liveness-Prüfung nicht bestanden',
                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                  textAlign:
                                      TextAlign.center,
                                ),

                                if (_leftMovement !=
                                        null &&
                                    _rightMovement !=
                                        null) ...[
                                  const SizedBox(
                                    height: 10,
                                  ),

                                  Text(
                                    'Links: ${_leftMovement!.toStringAsFixed(4)}',
                                  ),

                                  Text(
                                    'Rechts: ${_rightMovement!.toStringAsFixed(4)}',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 10,
                        ),

                        TextButton(
                          onPressed:
                              resetLiveness,
                          child: const Text(
                            'Prüfung wiederholen',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}