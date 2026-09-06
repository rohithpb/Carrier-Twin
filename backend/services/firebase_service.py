import os
import json
from pathlib import Path
from typing import List, Dict, Any, Optional

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"

# Memory state cache for Demo Mode updates
_memory_students: Optional[List[Dict[str, Any]]] = None
_memory_opportunities: Optional[List[Dict[str, Any]]] = None

class FirebaseService:
    def __init__(self):
        self.firebase_initialized = False
        self.db = None
        self._init_firebase()

    def _init_firebase(self):
        # Try initializing Firebase if credentials exist
        sa_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "serviceAccountKey.json")
        full_sa_path = Path(sa_path) if os.path.isabs(sa_path) else BASE_DIR / sa_path
        if not full_sa_path.exists():
            full_sa_path = BASE_DIR.parent / sa_path

        if full_sa_path.exists():
            try:
                import firebase_admin
                from firebase_admin import credentials, firestore
                if not firebase_admin._apps:
                    cred = credentials.Certificate(str(full_sa_path))
                    firebase_admin.initialize_app(cred)
                self.db = firestore.client()
                self.firebase_initialized = True
                print("Firebase Firestore initialized successfully.")
            except Exception as e:
                print(f"Firebase initialization warning: {e}. Falling back to local Demo Mode data.")
                self.firebase_initialized = False
        else:
            print("No Firebase service account found. Using local JSON demo data mode.")

    def get_all_students(self) -> List[Dict[str, Any]]:
        global _memory_students
        if self.firebase_initialized and self.db:
            try:
                docs = self.db.collection("students").stream()
                results = []
                for doc in docs:
                    data = doc.to_dict()
                    if "id" not in data or not data["id"]:
                        data["id"] = doc.id
                    results.append(data)
                if results:
                    return results
            except Exception as e:
                print(f"Firestore read error: {e}")

        # Local Demo Mode Fallback
        if _memory_students is None:
            file_path = DATA_DIR / "demo_students.json"
            if file_path.exists():
                with open(file_path, "r", encoding="utf-8") as f:
                    _memory_students = json.load(f)
            else:
                _memory_students = []
        return _memory_students

    def get_student_by_id(self, student_id: str) -> Optional[Dict[str, Any]]:
        students = self.get_all_students()
        for s in students:
            if s.get("id") == student_id:
                return s
        return None

    def update_student(self, student_id: str, updated_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        global _memory_students
        if self.firebase_initialized and self.db:
            try:
                self.db.collection("students").doc(student_id).set(updated_data, merge=True)
            except Exception as e:
                print(f"Firestore update error: {e}")

        students = self.get_all_students()
        for i, s in enumerate(students):
            if s.get("id") == student_id:
                students[i].update(updated_data)
                _memory_students = students
                return students[i]
        return None

    def get_all_mentors(self) -> List[Dict[str, Any]]:
        file_path = DATA_DIR / "demo_mentors.json"
        if file_path.exists():
            with open(file_path, "r", encoding="utf-8") as f:
                return json.load(f)
        return []

    def get_mentor_by_id(self, mentor_id: str) -> Optional[Dict[str, Any]]:
        mentors = self.get_all_mentors()
        for m in mentors:
            if m.get("id") == mentor_id:
                return m
        return None

    def get_all_recruiters(self) -> List[Dict[str, Any]]:
        file_path = DATA_DIR / "demo_recruiters.json"
        if file_path.exists():
            with open(file_path, "r", encoding="utf-8") as f:
                return json.load(f)
        return []

    def get_all_opportunities(self) -> List[Dict[str, Any]]:
        global _memory_opportunities
        if _memory_opportunities is None:
            file_path = DATA_DIR / "demo_opportunities.json"
            if file_path.exists():
                with open(file_path, "r", encoding="utf-8") as f:
                    _memory_opportunities = json.load(f)
            else:
                _memory_opportunities = []
        return _memory_opportunities

db_service = FirebaseService()
