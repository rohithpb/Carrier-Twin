import os
import json
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"

def seed_demo_data():
    print("Checking Firebase Firestore connection...")
    sa_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "serviceAccountKey.json")
    full_sa_path = Path(sa_path) if os.path.isabs(sa_path) else BASE_DIR / sa_path
    if not full_sa_path.exists():
        full_sa_path = BASE_DIR.parent / sa_path

    if not full_sa_path.exists():
        print(f"Service account file '{full_sa_path}' not found.")
        print("Backend is running in local Demo Mode using backend/data JSON files directly.")
        return

    try:
        import firebase_admin
        from firebase_admin import credentials, firestore

        if not firebase_admin._apps:
            cred = credentials.Certificate(str(full_sa_path))
            firebase_admin.initialize_app(cred)

        db = firestore.client()
        print("Connected to Firestore. Seeding demo data...")

        # 1. Seed Students
        with open(DATA_DIR / "demo_students.json", "r", encoding="utf-8") as f:
            students = json.load(f)
            for s in students:
                doc_ref = db.collection("students").document(s["id"])
                doc_ref.set(s, merge=True)
                print(f"  + Synced student: {s['name']} ({s['id']})")

        # 2. Seed Mentors
        with open(DATA_DIR / "demo_mentors.json", "r", encoding="utf-8") as f:
            mentors = json.load(f)
            for m in mentors:
                doc_ref = db.collection("mentors").document(m["id"])
                doc_ref.set(m, merge=True)
                print(f"  + Synced mentor: {m['name']} ({m['id']})")

        # 3. Seed Recruiters
        with open(DATA_DIR / "demo_recruiters.json", "r", encoding="utf-8") as f:
            recruiters = json.load(f)
            for r in recruiters:
                doc_ref = db.collection("recruiters").document(r["id"])
                doc_ref.set(r, merge=True)
                print(f"  + Synced recruiter: {r['name']} ({r['id']})")

        # 4. Seed Opportunities
        with open(DATA_DIR / "demo_opportunities.json", "r", encoding="utf-8") as f:
            opps = json.load(f)
            for o in opps:
                doc_ref = db.collection("opportunities").document(o["id"])
                doc_ref.set(o, merge=True)
                print(f"  + Synced opportunity: {o['title']} ({o['id']})")

        print("Firestore seeding completed successfully!")

    except Exception as e:
        print(f"Error seeding Firestore: {e}")

if __name__ == "__main__":
    seed_demo_data()
