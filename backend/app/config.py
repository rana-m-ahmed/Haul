"""
Application configuration using Pydantic BaseSettings.
Reads from environment variables (HF Spaces Secrets) with .env fallback for local dev.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Central configuration for the Haul backend."""

    # --- API Keys ---
    gemini_api_key: str = ""
    groq_api_key: str = ""
    stripe_secret_key: str = ""
    stripe_publishable_key: str = "pk_test_TYooMQauvdEDq54NiTphI7jx"
    unsplash_access_key: str = ""  # Only needed by seed script
    haul_api_key: str = "test_key_123"

    # --- Firebase ---
    # Base64-encoded Firebase service account JSON
    firebase_credentials_json: str = ""
    firestore_database_id: str = "(default)"

    # --- App Settings ---
    environment: str = "development"
    log_level: str = "INFO"
    app_name: str = "Haul API"
    app_version: str = "1.0.0"

    # --- Cache Settings ---
    # How often to refresh the in-memory product catalog (seconds)
    product_cache_ttl: int = 1800  # 30 minutes

    # --- Rate Limits ---
    gemini_daily_limit: int = 1400  # Stay under 1,500/day free tier
    groq_daily_limit: int = 14000  # Stay under 14,400/day free tier

    # --- Timeouts (seconds) ---
    gemini_timeout: float = 5.0
    groq_timeout: float = 4.0
    stripe_timeout: float = 10.0

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )


# Singleton instance — created once, reused everywhere via FastAPI dependency injection
settings = Settings()
