from flask import Flask, request, jsonify
from flask_cors import CORS

from PIL import Image

import pytesseract
import io
import re
import os

import cv2
import numpy as np

import firebase_admin
from firebase_admin import credentials
from firebase_admin import auth
from firebase_admin import firestore


app = Flask(__name__)
CORS(app)


# ============================================================
# TESSERACT
# ============================================================

pytesseract.pytesseract.tesseract_cmd = (
    r"C:\Program Files\Tesseract-OCR\tesseract.exe"
)


# ============================================================
# FIREBASE ADMIN
# ============================================================

BASE_DIR = os.path.dirname(
    os.path.abspath(__file__)
)

SERVICE_ACCOUNT_PATH = os.path.join(
    BASE_DIR,
    "serviceAccountKey.json",
)

firebase_credential = credentials.Certificate(
    SERVICE_ACCOUNT_PATH
)

firebase_admin.initialize_app(
    firebase_credential
)

db = firestore.client()


# ============================================================
# FACE-MODELLE
# ============================================================

FACE_DETECTION_MODEL = os.path.join(
    BASE_DIR,
    "models",
    "face_detection_yunet_2023mar.onnx",
)

FACE_RECOGNITION_MODEL = os.path.join(
    BASE_DIR,
    "models",
    "face_recognition_sface_2021dec.onnx",
)


face_detector = cv2.FaceDetectorYN.create(
    FACE_DETECTION_MODEL,
    "",
    (320, 320),
    score_threshold=0.8,
    nms_threshold=0.3,
    top_k=5000,
)


face_recognizer = cv2.FaceRecognizerSF.create(
    FACE_RECOGNITION_MODEL,
    "",
)


# ============================================================
# VERIFICATION STATUS
# ============================================================

# Nur für unseren lokalen Prototyp.
#
# Hier merkt sich der Backend-Server,
# welche Schritte ein Benutzer erfolgreich abgeschlossen hat.
#
# Beispiel:
#
# {
#     "firebaseUid": {
#         "ocr": True,
#         "face": True,
#         "liveness": False
#     }
# }

verification_sessions = {}


def get_verification_session(uid):
    if uid not in verification_sessions:
        verification_sessions[uid] = {
            "ocr": False,
            "face": False,
            "liveness": False,
        }

    return verification_sessions[uid]


# ============================================================
# FIREBASE TOKEN PRÜFEN
# ============================================================

def get_authenticated_user():

    authorization = request.headers.get(
        "Authorization"
    )

    if not authorization:
        return None

    if not authorization.startswith(
        "Bearer "
    ):
        return None

    token = authorization[
        len("Bearer "):
    ].strip()

    if not token:
        return None

    try:
        decoded_token = auth.verify_id_token(
            token
        )

        return decoded_token

    except Exception as e:
        print(
            "Firebase Token Fehler:",
            e,
        )

        return None


# ============================================================
# OCR-DATEN AUSLESEN
# ============================================================

def extract_identity_data(text):

    surname = None
    forename = None
    date_of_birth = None
    nationality = None

    lines = [
        line.strip()
        for line in text.splitlines()
        if line.strip()
    ]

    # =========================
    # NAME UND VORNAME
    # =========================

    for index, line in enumerate(lines):

        upper_line = line.upper()

        if (
            "NAMEN" in upper_line
            and "VORNAMEN" in upper_line
        ):

            if index + 1 < len(lines):
                surname = lines[
                    index + 1
                ]

            if index + 2 < len(lines):
                forename = lines[
                    index + 2
                ]

            break

    # =========================
    # GEBURTSDATUM
    # =========================

    date_pattern = re.compile(
        r"\b(\d{2})[\s.\-/](\d{2})[\s.\-/](\d{4})\b"
    )

    for line in lines:

        match = date_pattern.search(
            line
        )

        if match:

            day, month, year = (
                match.groups()
            )

            try:

                year_number = int(
                    year
                )

                if (
                    1900
                    <= year_number
                    <= 2100
                ):
                    date_of_birth = (
                        f"{day}.{month}.{year}"
                    )

                    break

            except ValueError:
                pass

    # =========================
    # NATIONALITÄT
    # =========================

    nationality_pattern = re.compile(
        r"\b(SYR|DEU|TUR|IRQ|AFG|UKR)\b",
        re.IGNORECASE,
    )

    for line in lines:

        match = nationality_pattern.search(
            line
        )

        if match:

            nationality = (
                match.group(1).upper()
            )

            break

    return {
        "surname": surname,
        "forename": forename,
        "dateOfBirth": date_of_birth,
        "nationality": nationality,
    }


def check_required_identity_data(
    identity_data,
):

    return (
        identity_data["surname"]
        is not None

        and identity_data["forename"]
        is not None

        and identity_data["dateOfBirth"]
        is not None

        and identity_data["nationality"]
        is not None
    )


# ============================================================
# BILD FÜR OPENCV LADEN
# ============================================================

def decode_image(image_bytes):

    image_array = np.frombuffer(
        image_bytes,
        dtype=np.uint8,
    )

    image = cv2.imdecode(
        image_array,
        cv2.IMREAD_COLOR,
    )

    if image is None:
        raise ValueError(
            "Das Bild konnte nicht gelesen werden."
        )

    return image


# ============================================================
# GESICHT ERKENNEN
# ============================================================

def detect_face(image):

    height, width = (
        image.shape[:2]
    )

    face_detector.setInputSize(
        (width, height)
    )

    _, faces = (
        face_detector.detect(
            image
        )
    )

    if (
        faces is None
        or len(faces) == 0
    ):
        return None

    best_face = max(
        faces,
        key=lambda face: face[-1],
    )

    return best_face


# ============================================================
# FACE FEATURE
# ============================================================

def get_face_feature(image):

    face = detect_face(
        image
    )

    if face is None:
        return None

    aligned_face = (
        face_recognizer.alignCrop(
            image,
            face,
        )
    )

    feature = (
        face_recognizer.feature(
            aligned_face
        )
    )

    return feature


# ============================================================
# LIVENESS LANDMARKS
# ============================================================

def get_face_landmarks(image):

    face = detect_face(
        image
    )

    if face is None:
        return None

    x = float(
        face[0]
    )

    width = float(
        face[2]
    )

    right_eye_x = float(
        face[4]
    )

    left_eye_x = float(
        face[6]
    )

    nose_x = float(
        face[8]
    )

    if width <= 0:
        return None

    right_eye_relative = (
        right_eye_x - x
    ) / width

    left_eye_relative = (
        left_eye_x - x
    ) / width

    nose_relative = (
        nose_x - x
    ) / width

    return {
        "rightEyeX":
            right_eye_relative,

        "leftEyeX":
            left_eye_relative,

        "noseX":
            nose_relative,
    }


def calculate_head_direction(
    image,
):

    landmarks = (
        get_face_landmarks(
            image
        )
    )

    if landmarks is None:
        return None

    right_eye = landmarks[
        "rightEyeX"
    ]

    left_eye = landmarks[
        "leftEyeX"
    ]

    nose = landmarks[
        "noseX"
    ]

    eye_center = (
        right_eye
        + left_eye
    ) / 2.0

    direction_value = (
        nose - eye_center
    )

    return direction_value


# ============================================================
# START
# ============================================================

@app.route(
    "/",
    methods=["GET"],
)
def start():

    return jsonify({
        "status": "ok",
        "message":
            "OCR-, Face-, Liveness- und Firebase-Backend läuft."
    })


# ============================================================
# OCR
# ============================================================

@app.route(
    "/ocr",
    methods=["POST"],
)
def ocr():

    # Firebase Benutzer prüfen.
    user = get_authenticated_user()

    if user is None:
        return jsonify({
            "success": False,
            "message":
                "Benutzer ist nicht authentifiziert."
        }), 401

    uid = user["uid"]

    if "image" not in request.files:

        return jsonify({
            "success": False,
            "message":
                "Kein Bild wurde übertragen."
        }), 400

    image_file = request.files[
        "image"
    ]

    if image_file.filename == "":

        return jsonify({
            "success": False,
            "message":
                "Keine Datei ausgewählt."
        }), 400

    try:

        image_bytes = (
            image_file.read()
        )

        image = Image.open(
            io.BytesIO(
                image_bytes
            )
        )

        text = (
            pytesseract
            .image_to_string(
                image,
                lang="deu",
            )
        )

        identity_data = (
            extract_identity_data(
                text
            )
        )

        verification_passed = (
            check_required_identity_data(
                identity_data
            )
        )

        # OCR-Status serverseitig merken.
        session = (
            get_verification_session(
                uid
            )
        )

        session["ocr"] = (
            verification_passed
        )

        # Wenn OCR erneut fehlschlägt,
        # spätere Schritte zurücksetzen.
        if not verification_passed:
            session["face"] = False
            session["liveness"] = False

        return jsonify({
            "success": True,

            "verificationPassed":
                verification_passed,

            "data":
                identity_data,

            "rawText":
                text,
        })

    except Exception as e:

        return jsonify({
            "success": False,
            "message":
                str(e),
        }), 500


# ============================================================
# FACE VERIFICATION
# ============================================================

@app.route(
    "/face-verify",
    methods=["POST"],
)
def face_verify():

    user = get_authenticated_user()

    if user is None:

        return jsonify({
            "success": False,
            "faceMatch": False,
            "message":
                "Benutzer ist nicht authentifiziert."
        }), 401

    uid = user["uid"]

    session = (
        get_verification_session(
            uid
        )
    )

    # Face Verification darf erst
    # nach erfolgreicher OCR erfolgen.
    if session["ocr"] is not True:

        return jsonify({
            "success": False,
            "faceMatch": False,
            "message":
                "Die OCR-Prüfung wurde noch nicht erfolgreich abgeschlossen."
        }), 403

    if (
        "documentImage"
        not in request.files
    ):

        return jsonify({
            "success": False,
            "faceMatch": False,
            "message":
                "Kein Ausweisbild übertragen."
        }), 400

    if (
        "selfieImage"
        not in request.files
    ):

        return jsonify({
            "success": False,
            "faceMatch": False,
            "message":
                "Kein Selfie übertragen."
        }), 400

    try:

        document_bytes = (
            request.files[
                "documentImage"
            ].read()
        )

        selfie_bytes = (
            request.files[
                "selfieImage"
            ].read()
        )

        document_image = (
            decode_image(
                document_bytes
            )
        )

        selfie_image = (
            decode_image(
                selfie_bytes
            )
        )

        document_feature = (
            get_face_feature(
                document_image
            )
        )

        if document_feature is None:

            session["face"] = False
            session["liveness"] = False

            return jsonify({
                "success": False,
                "faceMatch": False,
                "message":
                    "Auf dem Ausweisdokument wurde kein Gesicht erkannt."
            }), 400

        selfie_feature = (
            get_face_feature(
                selfie_image
            )
        )

        if selfie_feature is None:

            session["face"] = False
            session["liveness"] = False

            return jsonify({
                "success": False,
                "faceMatch": False,
                "message":
                    "Auf dem Selfie wurde kein Gesicht erkannt."
            }), 400

        similarity = (
            face_recognizer.match(
                document_feature,
                selfie_feature,
                cv2.FaceRecognizerSF_FR_COSINE,
            )
        )

        threshold = 0.363

        face_match = (
            similarity
            >= threshold
        )

        # Face-Status serverseitig merken.
        session["face"] = (
            bool(face_match)
        )

        if not face_match:
            session["liveness"] = False

        return jsonify({
            "success": True,

            "faceMatch":
                bool(face_match),

            "similarity":
                round(
                    float(
                        similarity
                    ),
                    4,
                ),

            "threshold":
                threshold,
        })

    except Exception as e:

        session["face"] = False
        session["liveness"] = False

        return jsonify({
            "success": False,
            "faceMatch": False,
            "message":
                str(e),
        }), 500


# ============================================================
# LIVENESS VERIFICATION
# ============================================================

@app.route(
    "/liveness-verify",
    methods=["POST"],
)
def liveness_verify():

    user = get_authenticated_user()

    if user is None:

        return jsonify({
            "success": False,
            "livenessPassed": False,
            "message":
                "Benutzer ist nicht authentifiziert."
        }), 401

    uid = user["uid"]

    session = (
        get_verification_session(
            uid
        )
    )

    # Liveness darf erst nach
    # OCR + Face Match erfolgen.
    if (
        session["ocr"] is not True
        or session["face"] is not True
    ):

        return jsonify({
            "success": False,
            "livenessPassed": False,
            "message":
                "OCR und Gesichtsvergleich müssen zuerst erfolgreich abgeschlossen werden."
        }), 403

    required_images = [
        "frontImage",
        "leftImage",
        "rightImage",
    ]

    for image_name in required_images:

        if (
            image_name
            not in request.files
        ):

            return jsonify({
                "success": False,
                "livenessPassed":
                    False,
                "message":
                    f"{image_name} fehlt."
            }), 400

    try:

        front_bytes = (
            request.files[
                "frontImage"
            ].read()
        )

        left_bytes = (
            request.files[
                "leftImage"
            ].read()
        )

        right_bytes = (
            request.files[
                "rightImage"
            ].read()
        )

        front_image = (
            decode_image(
                front_bytes
            )
        )

        left_image = (
            decode_image(
                left_bytes
            )
        )

        right_image = (
            decode_image(
                right_bytes
            )
        )

        front_direction = (
            calculate_head_direction(
                front_image
            )
        )

        left_direction = (
            calculate_head_direction(
                left_image
            )
        )

        right_direction = (
            calculate_head_direction(
                right_image
            )
        )

        if (
            front_direction is None
            or left_direction is None
            or right_direction is None
        ):

            session["liveness"] = False

            return jsonify({
                "success": False,
                "livenessPassed":
                    False,
                "message":
                    "In mindestens einer Aufnahme wurde kein Gesicht erkannt."
            }), 400

        left_difference = (
            left_direction
            - front_direction
        )

        right_difference = (
            right_direction
            - front_direction
        )

        movement_threshold = 0.03

        opposite_directions = (
            left_difference
            * right_difference
        ) < 0

        enough_left_movement = (
            abs(
                left_difference
            )
            >= movement_threshold
        )

        enough_right_movement = (
            abs(
                right_difference
            )
            >= movement_threshold
        )

        liveness_passed = (
            opposite_directions
            and enough_left_movement
            and enough_right_movement
        )

        session["liveness"] = (
            bool(liveness_passed)
        )

        # ==============================================
        # ALLE PRÜFUNGEN ERFOLGREICH
        # ==============================================

        verification_completed = (
            session["ocr"] is True
            and session["face"] is True
            and session["liveness"] is True
        )

        if verification_completed:

            user_ref = (
                db.collection("users")
                .document(uid)
            )

            # Firebase Admin schreibt
            # isVerified serverseitig.
            user_ref.update({
                "isVerified": True,
                "verifiedAt":
                    firestore.SERVER_TIMESTAMP,
            })

        return jsonify({
            "success": True,

            "livenessPassed":
                bool(
                    liveness_passed
                ),

            "verificationCompleted":
                verification_completed,

            "values": {
                "front":
                    round(
                        front_direction,
                        4,
                    ),

                "left":
                    round(
                        left_direction,
                        4,
                    ),

                "right":
                    round(
                        right_direction,
                        4,
                    ),
            },

            "movement": {
                "left":
                    round(
                        left_difference,
                        4,
                    ),

                "right":
                    round(
                        right_difference,
                        4,
                    ),
            },

            "threshold":
                movement_threshold,
        })

    except Exception as e:

        session["liveness"] = False

        return jsonify({
            "success": False,
            "livenessPassed":
                False,
            "message":
                str(e),
        }), 500


# ============================================================
# VERIFICATION STATUS
# ============================================================

@app.route(
    "/verification-status",
    methods=["GET"],
)
def verification_status():

    user = get_authenticated_user()

    if user is None:

        return jsonify({
            "success": False,
            "message":
                "Benutzer ist nicht authentifiziert."
        }), 401

    uid = user["uid"]

    session = (
        get_verification_session(
            uid
        )
    )

    return jsonify({
        "success": True,

        "ocr":
            session["ocr"],

        "face":
            session["face"],

        "liveness":
            session["liveness"],

        "verificationCompleted": (
            session["ocr"]
            and session["face"]
            and session["liveness"]
        ),
    })


# ============================================================
# SERVER STARTEN
# ============================================================

if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True,
    )