# Wahl-App

**Plattformübergreifende App für sichere Online-Wahlen mit Identitätsprüfung.**
Wählerinnen und Wähler registrieren sich, bestätigen ihre Identität per Ausweis-Scan und Gesichtsabgleich und geben ihre Stimme genau einmal ab. Ergebnisse und Statistiken werden live angezeigt. Administratoren verwalten Parteien und Wahl.

> 🚧 **Status: In Entwicklung.** Aktuelles Teamprojekt an der Hochschule Bochum (4 Personen). Die Kernfunktionen laufen bereits, weitere Funktionen werden laufend ergänzt.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?logo=flask&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black)
![OpenCV](https://img.shields.io/badge/OpenCV-5C3EE8?logo=opencv&logoColor=white)

---

## Funktionen

**Für Wählende**
- Registrierung und Login mit **Firebase Authentication**, inkl. E-Mail-Bestätigung und Passwort-Reset
- **Identitätsprüfung in drei Schritten:**
  1. **Ausweis-Scan** – Name, Geburtsdatum und Nationalität werden per OCR (Tesseract) ausgelesen
  2. **Gesichtsabgleich** – Selfie wird mit dem Ausweisfoto verglichen (OpenCV, YuNet + SFace)
  3. **Liveness-Check** – Kopfbewegungen vor der Kamera, damit kein Foto verwendet werden kann
- Optionale **biometrische Bestätigung** (Fingerabdruck / Face ID) vor der Stimmabgabe
- Übersicht der **Parteien** mit Detailseiten und Wahlinformationen
- **Stimmabgabe nur einmal pro Person** – abgesichert über eine Firestore-Transaktion
- **Ergebnisse und Statistiken** in Echtzeit

**Für Administratoren**
- **Admin-Bereich** mit rollenbasiertem Zugriff
- Verwaltung von Parteien und Benutzern, Dashboard mit Übersicht

## Mein Beitrag

Ich habe sowohl im **Backend (Python)** als auch im **Frontend (Flutter/Dart)** mitentwickelt:

- **Firebase-Anbindung** für Authentifizierung und Firestore-Datenbank
- **Benutzerverwaltung** (Registrierung, Login, Rollen)
- **Abstimmungsfunktion** mit Schutz vor doppelter Stimmabgabe
- **Ergebnis- und Statistik-Ansichten**
- **Admin-Bereich**

## Tech-Stack

| Bereich | Technologien |
|---|---|
| App (Frontend) | Flutter, Dart – läuft auf Android, iOS, Web, Windows, macOS, Linux |
| Backend | Python, Flask, Flask-CORS |
| Bildverarbeitung | OpenCV (YuNet-Gesichtserkennung, SFace-Gesichtsabgleich), Tesseract OCR, Pillow, NumPy |
| Datenbank & Auth | Firebase Authentication, Cloud Firestore, Firebase Admin SDK |
| Gerätefunktionen | Kamera, Biometrie (`local_auth`) |

## Architektur

```
┌───────────────────┐   Firebase Auth / Firestore   ┌────────────────────┐
│   Flutter-App     │ ◀──────────────────────────▶  │     Firebase       │
│                   │                               │  (Auth, Firestore) │
│                   │   HTTP + ID-Token             └─────────▲──────────┘
│                   │ ──────────────┐                         │ Admin SDK
└───────────────────┘               ▼                         │
                        ┌──────────────────────────────┐      │
                        │  Python-Backend (Flask)      │ ─────┘
                        │  OCR · Gesichtsabgleich ·    │
                        │  Liveness-Check              │
                        └──────────────────────────────┘
```

Das Backend prüft bei jeder Anfrage das Firebase-ID-Token und speichert das Ergebnis der Verifizierung in Firestore.

## Projektstruktur

```
wahl-app/
├── lib/
│   ├── main.dart
│   ├── screens/        # Login, Registrierung, Verifizierung, Wahl, Ergebnisse, Admin, ...
│   └── services/       # Biometrie, Auth-Token
├── backend/
│   ├── app.py          # Flask-API: /ocr, /face-verify, /liveness-verify, /verification-status
│   └── models/         # ONNX-Modelle für Gesichtserkennung
└── android/, ios/, web/, windows/, macos/, linux/
```

## Lokal starten

### Voraussetzungen
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.12+)
- Python 3.10+
- [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) mit deutschem Sprachpaket
- Ein eigenes [Firebase-Projekt](https://console.firebase.google.com/) mit aktivierter E-Mail-Authentifizierung und Firestore

### 1. Firebase einrichten

Die Firebase-Konfiguration ist aus Sicherheitsgründen nicht im Repository enthalten.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Das erzeugt `lib/firebase_options.dart`. Für das Backend in der Firebase-Konsole unter *Projekteinstellungen → Dienstkonten* einen privaten Schlüssel erzeugen und als `backend/serviceAccountKey.json` speichern.

### 2. Backend starten

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install flask flask-cors pillow pytesseract opencv-python numpy firebase-admin
python app.py
```

Das Backend läuft dann unter `http://127.0.0.1:5000`.

### 3. App starten

```bash
flutter pub get
flutter run
```

> Hinweis: Die App erwartet das Backend unter `127.0.0.1:5000`. Auf einem Android-Emulator oder echtem Gerät muss die Adresse entsprechend angepasst werden (z. B. `10.0.2.2` für den Emulator).

### Admin-Zugang

Um einen Benutzer zum Administrator zu machen, in Firestore im Dokument `users/<uid>` das Feld `isAdmin: true` setzen.

## Screenshots

<!-- Hier 2–3 Screenshots einfügen, z. B.:
![Identitätsprüfung](docs/verification.png)
![Stimmabgabe](docs/vote.png)
![Ergebnisse](docs/results.png)
-->

## Team

Entwickelt im Rahmen eines Studienprojekts an der Hochschule Bochum von einem vierköpfigen Team.
