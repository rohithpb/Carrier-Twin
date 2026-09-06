# CareerTwin — AI-Powered Educational Digital Twin & Career Development Platform

CareerTwin is an AI-powered Educational Digital Twin platform for colleges and universities. The platform tracks student academics, skills, MOOCs, workshops, internships, projects, and certifications from Year 1 to Graduation.

---

## Architecture

```
CareerTwin Frontend (Flutter)
            │
            ▼
    FastAPI REST API (Port 8000)
            │
   ┌────────┴────────┐
   ▼                 ▼
Firebase       AI/ML Engine
Firestore            │
   │                 ▼
   │            Pickle Model
   │             (.pkl file)
   ▼
Student Data, Mentors, Recruiters, Opportunities
```

---

## Quick Start Guide

### 1. Prerequisites
- Python 3.10+
- Flutter SDK 3.0+
- Android Studio / Android Emulator (Pixel 7)

---

### 2. Backend Setup & Run

1. Navigate to the `backend/` directory:
   ```bash
   cd backend
   ```

2. Install Python dependencies:
   ```bash
   python -m pip install -r requirements.txt
   ```

3. Configure environment variables (copy `.env.example` to `.env`):
   ```bash
   DEMO_MODE=true
   MODEL_PATH=models/career_model.pkl
   FIREBASE_PROJECT_ID=
   FIREBASE_SERVICE_ACCOUNT_PATH=serviceAccountKey.json
   PORT=8000
   ```

4. Start the FastAPI backend server:
   ```bash
   python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

5. Access interactive Swagger API documentation:
   - **Swagger UI**: http://localhost:8000/docs
   - **Health Check**: http://localhost:8000/api/health

---

### 3. ML Model (.pkl) Setup & Fallback Mode

1. Create directory `backend/models/`:
   ```bash
   mkdir backend/models
   ```
2. Copy your trained model files into `backend/models/`:
   - `career_model.pkl` (Main model)
   - `scaler.pkl` (Optional Feature Scaler)
   - `label_encoder.pkl` (Optional Label Encoder)

3. **Fallback Mode**: If `career_model.pkl` is missing or fails to load, CareerTwin automatically uses the built-in **Rule-Based Career Recommendation Engine** (`ML_MODE=disabled`) without crashing.

---

### 4. Demo Data & Seeding

The application comes pre-loaded with realistic demo datasets in `backend/data/`:
- **30 Students**: Year 1–4 across CS, BCA, IT, ECE with realistic skill levels and readiness scores.
- **5 Mentors**: Assigned to department classes and student groups.
- **5 Recruiters**: Hiring for Data Analyst, Cloud Engineer, ML Engineer, Full Stack, and Cybersecurity roles.
- **40 Opportunities**: Internships, Workshops, MOOCs, Hackathons, Certifications, and Jobs.

To seed Firebase Firestore (if credentials exist):
```bash
cd backend
python scripts/seed_demo_data.py
```

---

### 5. Frontend Setup & Run (Flutter)

1. Launch Android Emulator (Pixel 7):
   ```bash
   flutter emulators --launch Pixel_7
   ```

2. Start the Flutter application:
   ```bash
   flutter run -d emulator-5554
   ```

The Flutter app automatically connects to the FastAPI backend at `http://10.0.2.2:8000/api`.

---

## API Endpoints Summary

- `GET /api/health` — Health check & ML status
- `GET /api/students` — Fetch all 30 demo students
- `GET /api/students/{id}/digital-twin` — Complete Digital Twin profile
- `GET /api/students/{id}/readiness` — Career Readiness Score & breakdown
- `POST /api/students/{id}/activities` — Add activity & recalculate score
- `POST /api/predict-career` — Career role predictions (ML or Rule-based)
- `GET /api/students/{id}/recommendations` — Top 10 matched opportunities & Next Best Action
- `GET /api/mentors/{id}/analytics` — Mentor dashboard analytics
- `POST /api/recruiters/{id}/match-students` — Recruiter student candidate matching
- `GET /api/placement/analytics` — Placement officer batch readiness analytics
