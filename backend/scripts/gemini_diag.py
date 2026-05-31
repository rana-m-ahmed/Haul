#!/usr/bin/env python3
"""Diagnostic script to inspect available Gemini/Generative AI models via google.generativeai.
Writes output to artifacts/gemini_models.json
"""
import os
import json
import google.generativeai as genai

API_KEY = os.getenv("GEMINI_API_KEY")

# Fallback: read backend/.env if present
if not API_KEY:
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    env_path = os.path.normpath(env_path)
    if os.path.exists(env_path):
        try:
            with open(env_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#") or "=" not in line:
                        continue
                    k, v = line.split("=", 1)
                    if k.strip().upper() == "GEMINI_API_KEY":
                        API_KEY = v.strip().strip('"').strip("'")
                        break
        except Exception:
            pass
OUT = "artifacts/gemini_models.json"

def main():
    if not API_KEY:
        print("GEMINI_API_KEY missing in environment or .env")
        return
    genai.configure(api_key=API_KEY)
    info = {"has_list_models": False, "models": None, "attrs": []}

    # attempt to list models if function exists
    list_fn = getattr(genai, "list_models", None)
    if callable(list_fn):
        info["has_list_models"] = True
        try:
            models = list_fn()
            # ensure it's a list and JSON-serializable
            try:
                models_list = list(models)
            except TypeError:
                models_list = models

            serializable = []
            for m in models_list:
                if isinstance(m, dict):
                    serializable.append(m)
                else:
                    try:
                        serializable.append(m.__dict__)
                    except Exception:
                        serializable.append(str(m))

            info["models"] = serializable
        except Exception as e:
            info["models_error"] = str(e)

    # dump top-level attributes of genai module
    info["attrs"] = [a for a in dir(genai) if not a.startswith("_")]

    os.makedirs("artifacts", exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(info, f, indent=2)

    print(f"Diagnostic written to {OUT}")

if __name__ == "__main__":
    main()
