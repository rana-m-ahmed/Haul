"""
Shared dependencies: Firebase Admin SDK initialization and Firestore client.
The Firebase service account JSON is decoded from a base64 environment variable
to avoid checking credentials into source control.
"""

from __future__ import annotations

import base64
import json
import os
import tempfile
from functools import lru_cache

import firebase_admin
from firebase_admin import credentials, firestore

from app.config import settings
from app.utils.logging_config import get_logger

logger = get_logger("dependencies")

# ---------------------------------------------------------------------------
# Firebase Initialization
# ---------------------------------------------------------------------------

_firebase_app: firebase_admin.App | None = None
_firestore_client = None


def init_firebase() -> None:
    """
    Initialize Firebase Admin SDK from base64-encoded credentials.
    Safe to call multiple times — only initializes once.
    """
    global _firebase_app, _firestore_client

    if _firebase_app is not None:
        return

    creds_json = settings.firebase_credentials_json
    if not creds_json:
        logger.warning("FIREBASE_CREDENTIALS_JSON not set — Firebase will not be available")
        return

    try:
        # Decode base64 → JSON string → dict
        decoded = base64.b64decode(creds_json).decode("utf-8")
        creds_dict = json.loads(decoded)

        # Write to a temp file for the Firebase SDK
        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False
        )
        json.dump(creds_dict, tmp)
        tmp.close()

        cred = credentials.Certificate(tmp.name)
        _firebase_app = firebase_admin.initialize_app(cred)
        
        from google.cloud import firestore as gc_firestore
        _firestore_client = gc_firestore.Client.from_service_account_json(
            tmp.name, database=settings.firestore_database_id
        )

        # Clean up temp file
        os.unlink(tmp.name)

        logger.info("Firebase Admin SDK initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}", exc_info=True)
        raise


def get_firestore_client():
    """Return the cached Firestore client. Raises if Firebase not initialized."""
    if _firestore_client is None:
        raise RuntimeError(
            "Firestore client not initialized. Call init_firebase() first."
        )
    return _firestore_client


def get_firebase_app() -> firebase_admin.App | None:
    """Return the Firebase app instance."""
    return _firebase_app
