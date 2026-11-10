# Wahl-App

Plattformübergreifende App für sichere Online-Wahlen mit Identitätsprüfung und einem **Parteienvergleich mit belegten Quellen**. Wählerinnen und Wähler registrieren sich, bestätigen ihre Identität per Ausweis-Scan und Gesichtsabgleich und geben ihre Stimme genau einmal ab. Ergebnisse und Statistiken werden live angezeigt. Administratoren verwalten Parteien und Wahl.

> **Teamprojekt an der Hochschule Bochum (4 Personen), Status: in Entwicklung.**
> Die Entwicklung fand gemeinsam in einem Team-Repository statt (dort liegt die vollständige Commit-Historie). Dieses Repository ist eine Kopie des Projektstands. Meinen Anteil beschreibe ich unter [Mein Beitrag](#mein-beitrag).

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?logo=flask&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![OpenCV](https://img.shields.io/badge/OpenCV-5C3EE8?logo=opencv&logoColor=white)

## Funktionen

**Für Wählende**
- Registrierung und Login mit Firebase Authentication, inkl. E-Mail-Bestätigung und Passwort-Reset
- Identitätsprüfung in drei Schritten:
  1. **Ausweis-Scan**: Name, Geburtsdatum und Nationalität werden per OCR (Tesseract) ausgelesen
  2. **Gesichtsabgleich**: Selfie wird mit dem Ausweisfoto verglichen (OpenCV, YuNet + SFace)
  3. **Liveness-Check**: Kopfbewegungen vor der Kamera, damit kein Foto verwendet werden kann
- Optionale biometrische Bestätigung (Fingerabdruck / Face ID) vor der Stimmabgabe
- Übersicht der Parteien mit Detailseiten und Wahlinformationen
- **Parteienvergleich** mit 364 Zitaten aus den Wahlprogrammen und Link zur Originalstelle im PDF
- Stimmabgabe nur einmal pro Person, abgesichert über eine Firestore-Transaktion
- Ergebnisse und Statistiken in Echtzeit

**Für Administratoren**
- Admin-Bereich mit rollenbasiertem Zugriff
- Verwaltung von Parteien und Benutzern, Dashboard mit Übersicht

## Mein Beitrag

Mein Hauptbeitrag ist der **Parteienvergleich mit Quellenprüfung**. Zusätzlich habe ich bei der E-Mail-Verifizierung und im Backend mitgearbeitet.

**Parteienvergleich (Flutter + Python)**
- Datenmodell, Screen und Daten (`party_comparison_2025.json`) für den Vergleich der Parteien, mit 364 Zitaten aus den Wahlprogrammen
- **PDF-Quellenviewer**: Zu jedem Zitat zeigt die App die Originalstelle im Wahlprogramm-PDF an (`pdf_quote_matcher`, `verified_pdf_location`; Web-Variante mit pdf.js)
- **Python-Backend-Services** (`comparison_pdf`, `comparison_sources`) und Audit-Skripte, die die Quellenangaben überprüfen; Ergebnisse dokumentiert in `docs/party_comparison_pdf_audit.md`
- **Tests**: 5 Dart-Tests (`test/`) und 2 Python-Tests (`backend/test_comparison_*.py`)

**Mitarbeit**
- E-Mail-Verifizierung bei der Registrierung
- Backend (Python / Flask)

## Tech-Stack

| Bereich | Technologien |
|---|---|
| App (Frontend) | Flutter, Dart: Android, iOS, Web, Windows, macOS, Linux |
| Backend | Python, Flask, Flask-CORS |
| Bildverarbeitung | OpenCV (YuNet, SFace), Tesseract OCR, Pillow, NumPy |
| Datenbank & Auth | Firebase Authentication, Cloud Firestore, Firebase Admin SDK |
| Gerätefunktionen | Kamera, Biometrie (`local_auth`) |
| PDF | pdf.js (Web), Dart-PDF-Service |

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
                        │  Liveness · Quellenprüfung   │
                        └──────────────────────────────┘
```

Das Backend prüft bei jeder Anfrage das Firebase-ID-Token und speichert das Ergebnis der Verifizierung in Firestore.

## Projektstruktur

```
wahl-app/
├── lib/
│   ├── main.dart
│   ├── screens/        # Login, Verifizierung, Wahl, Ergebnisse, Parteienvergleich, Admin, ...
│   ├── services/       # Biometrie, Auth-Token, PDF-Quellenabgleich
│   └── models/
├── backend/
│   ├── app.py          # Flask-API: /ocr, /face-verify, /liveness-verify, /verification-status
│   ├── services/       # Quellenprüfung für den Parteienvergleich
│   ├── scripts/        # Audit-Skripte
│   └── models/         # ONNX-Modelle für Gesichtserkennung
├── assets/data/        # Daten des Parteienvergleichs
├── docs/               # Audit-Ergebnisse
├── test/               # Dart-Tests
└── android/, ios/, web/, windows/, macos/, linux/
```

## Lokal starten

**Voraussetzungen:** Flutter SDK (Dart 3.12+), Python 3.10+, Tesseract OCR mit deutschem Sprachpaket, ein eigenes Firebase-Projekt mit E-Mail-Authentifizierung und Firestore.

**1. Firebase einrichten**

Die Firebase-Konfiguration und der Service-Account-Schlüssel gehören aus Sicherheitsgründen nicht ins Repository.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Das erzeugt `lib/firebase_options.dart`. Für das Backend in der Firebase-Konsole unter *Projekteinstellungen → Dienstkonten* einen privaten Schlüssel erzeugen und als `backend/serviceAccountKey.json` speichern.

**2. Backend starten**

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install flask flask-cors pillow pytesseract opencv-python numpy firebase-admin
python app.py
```

Das Backend läuft dann unter `http://127.0.0.1:5000`.

**3. App starten**

```bash
flutter pub get
flutter run
```

> Die App erwartet das Backend unter `127.0.0.1:5000`. Auf einem Android-Emulator oder echtem Gerät muss die Adresse angepasst werden (z. B. `10.0.2.2` für den Emulator).

**Tests**

```bash
flutter test
```

**Admin-Zugang:** In Firestore im Dokument `users/<uid>` das Feld `isAdmin: true` setzen.

<!-- Screenshots: Bilder in docs/screenshots/ ablegen und hier einfügen, z. B.
![Parteienvergleich](docs/screenshots/parteienvergleich.png) -->

## Team

Entwickelt im Rahmen eines Studienprojekts an der Hochschule Bochum von einem vierköpfigen Team.
