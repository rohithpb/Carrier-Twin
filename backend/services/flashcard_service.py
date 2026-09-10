import uuid
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Dict, Any, Optional

from services.firebase_service import db_service
from services.sm2_service import sm2_service
from services.spaced_repetition_ml import spaced_repetition_ml

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"

# Local in-memory caches for demo/offline execution
_local_flashcards: Dict[str, List[Dict[str, Any]]] = {}
_local_review_logs: Dict[str, List[Dict[str, Any]]] = {}

class FlashcardService:
    """
    Manages Flashcard storage, review transactions, and telemetry logs
    with transparent Firestore sub-collection integration & local demo fallback.
    """

    def _get_local_file(self, student_id: str) -> Path:
        return DATA_DIR / f"flashcards_{student_id}.json"

    def _get_local_logs_file(self, student_id: str) -> Path:
        return DATA_DIR / f"review_logs_{student_id}.json"

    def _load_student_cards(self, student_id: str) -> List[Dict[str, Any]]:
        # Check Firestore first if active
        if db_service.firebase_initialized and db_service.db:
            try:
                docs = db_service.db.collection("students").document(student_id).collection("flashcards").stream()
                cards = []
                for doc in docs:
                    d = doc.to_dict()
                    d["id"] = doc.id
                    cards.append(d)
                if cards:
                    return cards
            except Exception as e:
                print(f"Firestore flashcard fetch warning: {e}")

        # In-Memory Cache
        if student_id in _local_flashcards:
            return _local_flashcards[student_id]

        # File-based Demo Persistence
        file_path = self._get_local_file(student_id)
        if file_path.exists():
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    cards = json.load(f)
                    _local_flashcards[student_id] = cards
                    return cards
            except Exception:
                pass

        # If completely empty, auto-seed default cards
        default_cards = self.seed_default_cards(student_id)
        return default_cards

    def _save_student_cards(self, student_id: str, cards: List[Dict[str, Any]]):
        _local_flashcards[student_id] = cards
        file_path = self._get_local_file(student_id)
        try:
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(cards, f, indent=2)
        except Exception as e:
            print(f"Error saving local cards: {e}")

    def _load_student_logs(self, student_id: str) -> List[Dict[str, Any]]:
        if db_service.firebase_initialized and db_service.db:
            try:
                docs = db_service.db.collection("students").document(student_id).collection("review_logs").stream()
                logs = []
                for doc in docs:
                    d = doc.to_dict()
                    d["id"] = doc.id
                    logs.append(d)
                if logs:
                    return logs
            except Exception:
                pass

        if student_id in _local_review_logs:
            return _local_review_logs[student_id]

        file_path = self._get_local_logs_file(student_id)
        if file_path.exists():
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    logs = json.load(f)
                    _local_review_logs[student_id] = logs
                    return logs
            except Exception:
                pass

        _local_review_logs[student_id] = []
        return []

    def _save_student_log(self, student_id: str, log_entry: Dict[str, Any]):
        # Save to Firestore if available
        if db_service.firebase_initialized and db_service.db:
            try:
                db_service.db.collection("students").document(student_id).collection("review_logs").document(log_entry["id"]).set(log_entry)
            except Exception as e:
                print(f"Firestore log write warning: {e}")

        logs = self._load_student_logs(student_id)
        logs.append(log_entry)
        _local_review_logs[student_id] = logs

        file_path = self._get_local_logs_file(student_id)
        try:
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(logs, f, indent=2)
        except Exception as e:
            print(f"Error saving local logs: {e}")

    def get_flashcards(
        self,
        student_id: str,
        due_only: bool = False,
        tag: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        cards = self._load_student_cards(student_id)
        now_iso = datetime.now(timezone.utc).isoformat()

        filtered = []
        for c in cards:
            if tag and tag.lower() != "all" and c.get("tag", "").lower() != tag.lower():
                continue
            if due_only:
                due_date = c.get("dueDate", "")
                if due_date and due_date > now_iso:
                    continue
            filtered.append(c)
        return filtered

    def get_card_by_id(self, student_id: str, card_id: str) -> Optional[Dict[str, Any]]:
        cards = self._load_student_cards(student_id)
        for c in cards:
            if c.get("id") == card_id:
                return c
        return None

    def create_flashcard(
        self,
        student_id: str,
        front: str,
        back: str,
        tag: str = "General",
        initial_interval: int = 1
    ) -> Dict[str, Any]:
        card_id = f"fc_{uuid.uuid4().hex[:8]}"
        now = datetime.now(timezone.utc)

        card_data = {
            "id": card_id,
            "student_id": student_id,
            "front": front.strip(),
            "back": back.strip(),
            "interval": initial_interval,
            "easeFactor": 2.5,
            "repetitions": 0,
            "dueDate": now.isoformat(),
            "tag": tag.strip() if tag else "General",
            "lastResponseTimeMs": 0,
            "created_at": now.isoformat()
        }

        # Save to Firestore if available
        if db_service.firebase_initialized and db_service.db:
            try:
                db_service.db.collection("students").document(student_id).collection("flashcards").document(card_id).set(card_data)
            except Exception as e:
                print(f"Firestore card write warning: {e}")

        cards = self._load_student_cards(student_id)
        cards.insert(0, card_data)
        self._save_student_cards(student_id, cards)
        return card_data

    def review_card(
        self,
        student_id: str,
        card_id: str,
        rating: int,
        response_time_ms: int
    ) -> Optional[Dict[str, Any]]:
        cards = self._load_student_cards(student_id)
        card_idx = -1
        for idx, c in enumerate(cards):
            if c.get("id") == card_id:
                card_idx = idx
                break

        if card_idx == -1:
            return None

        card = cards[card_idx]
        prev_interval = card.get("interval", 1)
        prev_ef = card.get("easeFactor", 2.5)
        prev_reps = card.get("repetitions", 0)

        # 1. SM-2 Standard Calculation
        sm2_result = sm2_service.calculate(
            rating=rating,
            current_interval=prev_interval,
            current_ease_factor=prev_ef,
            current_repetitions=prev_reps
        )

        # 2. Historical Telemetry Accuracy
        logs = self._load_student_logs(student_id)
        if logs:
            remembered_count = sum(1 for log in logs if log.get("remembered", 0) == 1)
            hist_acc = remembered_count / len(logs)
        else:
            hist_acc = 0.75

        # 3. Machine Learning Recall Prediction
        recall_prob = spaced_repetition_ml.predict_recall_probability(
            previous_interval=prev_interval,
            ease_factor=prev_ef,
            repetitions=prev_reps,
            historical_accuracy=hist_acc,
            response_time_ms=response_time_ms
        )

        # 4. Dynamic Interval Modulation
        ml_adjusted_interval, reason = spaced_repetition_ml.adjust_interval(
            sm2_interval=sm2_result["interval"],
            rating=rating,
            recall_probability=recall_prob,
            response_time_ms=response_time_ms
        )

        # 5. Update Card Object
        now = datetime.now(timezone.utc)
        from datetime import timedelta
        final_due = now + timedelta(days=ml_adjusted_interval)

        card["interval"] = ml_adjusted_interval
        card["easeFactor"] = sm2_result["easeFactor"]
        card["repetitions"] = sm2_result["repetitions"]
        card["dueDate"] = final_due.isoformat()
        card["lastResponseTimeMs"] = response_time_ms

        cards[card_idx] = card
        self._save_student_cards(student_id, cards)

        # Save to Firestore if available
        if db_service.firebase_initialized and db_service.db:
            try:
                db_service.db.collection("students").document(student_id).collection("flashcards").document(card_id).set(card, merge=True)
            except Exception as e:
                print(f"Firestore review update error: {e}")

        # 6. Log Telemetry to review_logs
        log_id = f"log_{uuid.uuid4().hex[:10]}"
        remembered_binary = 1 if rating >= 3 else 0
        log_entry = {
            "id": log_id,
            "student_id": student_id,
            "flashcard_id": card_id,
            "previous_interval": prev_interval,
            "new_interval": ml_adjusted_interval,
            "ease_factor": card["easeFactor"],
            "repetitions": card["repetitions"],
            "rating": rating,
            "remembered": remembered_binary,
            "response_time_ms": response_time_ms,
            "historical_accuracy": round(hist_acc, 2),
            "predicted_recall_probability": round(recall_prob, 2),
            "timestamp": now.isoformat()
        }
        self._save_student_log(student_id, log_entry)

        # Online ML weights training
        spaced_repetition_ml.train_on_logs(self._load_student_logs(student_id))

        return {
            "flashcard": card,
            "sm2_interval": sm2_result["interval"],
            "ml_adjusted_interval": ml_adjusted_interval,
            "predicted_recall_probability": round(recall_prob, 2),
            "interval_adjustment_reason": reason,
            "ease_factor_change": sm2_result["easeFactorChange"]
        }

    def get_stats(self, student_id: str) -> Dict[str, Any]:
        cards = self._load_student_cards(student_id)
        logs = self._load_student_logs(student_id)
        now_iso = datetime.now(timezone.utc).isoformat()

        total_cards = len(cards)
        due_cards = sum(1 for c in cards if c.get("dueDate", "") <= now_iso)

        retention_rate = 0.85
        avg_time = 3200
        if logs:
            remembered = sum(1 for l in logs if l.get("remembered", 0) == 1)
            retention_rate = round(remembered / len(logs), 2)
            times = [l.get("response_time_ms", 3000) for l in logs]
            avg_time = int(sum(times) / len(times))

        cards_by_topic: Dict[str, int] = {}
        for c in cards:
            tag = c.get("tag", "General")
            cards_by_topic[tag] = cards_by_topic.get(tag, 0) + 1

        topics = list(cards_by_topic.keys())
        return {
            "total_cards": total_cards,
            "due_cards": due_cards,
            "retention_rate": retention_rate,
            "average_response_time_ms": avg_time,
            "topics": topics,
            "cards_by_topic": cards_by_topic
        }

    def seed_default_cards(self, student_id: str) -> List[Dict[str, Any]]:
        from services.flashcard_generation_service import flashcard_generator
        now = datetime.now(timezone.utc)
        cards: List[Dict[str, Any]] = []

        all_topics = ["dbms", "python", "operating systems", "computer networks"]
        for t in all_topics:
            pairs = flashcard_generator._generate_from_curriculum(t, None, 3)
            for pair in pairs:
                cards.append({
                    "id": f"fc_seed_{uuid.uuid4().hex[:6]}",
                    "student_id": student_id,
                    "front": pair["front"],
                    "back": pair["back"],
                    "interval": 1,
                    "easeFactor": 2.5,
                    "repetitions": 0,
                    "dueDate": now.isoformat(),
                    "tag": pair["tag"],
                    "lastResponseTimeMs": 0,
                    "created_at": now.isoformat()
                })

        self._save_student_cards(student_id, cards)
        return cards

flashcard_service = FlashcardService()
