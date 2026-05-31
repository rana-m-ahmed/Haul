# Haul

Haul is a full-stack application composed of a Flutter frontend and a Python backend.

## Project Structure

- `frontend/`: Contains the Flutter application.
- `backend/`: Contains the Python backend (FastAPI).

## Setup & Running

### Frontend
Navigate to the `frontend` directory:
```bash
cd frontend
flutter pub get
flutter run
```

### Backend
Navigate to the `backend` directory:
```bash
cd backend
python -m venv .venv
# Activate the virtual environment
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

pip install -r requirements.txt
# Run the application (assuming FastAPI)
uvicorn app.main:app --reload
```
