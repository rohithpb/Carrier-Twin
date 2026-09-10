import json
import sys
from pathlib import Path

# Add backend directory to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

from main import app
from fastapi.testclient import TestClient
from services.sm2_service import sm2_service
from services.spaced_repetition_ml import spaced_repetition_ml

client = TestClient(app)

def test_sm2_calculations():
    print("Testing SM-2 algorithm calculations...")

    # Rating 1: Again (Lapse)
    res = sm2_service.calculate(rating=1, current_interval=10, current_ease_factor=2.5, current_repetitions=4)
    assert res["interval"] == 1
    assert res["repetitions"] == 0
    assert res["easeFactor"] == 2.30  # 2.5 - 0.20
    print("✓ Rating 1 (Again) correctly resets interval to 1 and drops ease factor.")

    # Rating 2: Hard
    res = sm2_service.calculate(rating=2, current_interval=5, current_ease_factor=2.30, current_repetitions=2)
    assert res["repetitions"] == 3
    assert res["easeFactor"] == 2.15  # 2.30 - 0.15
    assert res["interval"] == 6  # max(5+1, round(5*1.2))
    print("✓ Rating 2 (Hard) increases reps and scales interval conservatively.")

    # Rating 3: Good
    res = sm2_service.calculate(rating=3, current_interval=6, current_ease_factor=2.5, current_repetitions=2)
    assert res["repetitions"] == 3
    assert res["interval"] == 15  # round(6 * 2.5)
    print("✓ Rating 3 (Good) scales interval by ease factor.")

    # Rating 4: Easy
    res = sm2_service.calculate(rating=4, current_interval=6, current_ease_factor=2.5, current_repetitions=2)
    assert res["repetitions"] == 3
    assert res["easeFactor"] == 2.65  # 2.5 + 0.15
    assert res["interval"] >= 20  # round(6 * 2.65 * 1.3) = 21
    print("✓ Rating 4 (Easy) applies easy bonus and increments ease factor.")

def test_ml_pipeline():
    print("\nTesting ML recall probability prediction & interval modulation...")
    prob_high = spaced_repetition_ml.predict_recall_probability(
        previous_interval=5,
        ease_factor=2.5,
        repetitions=4,
        historical_accuracy=0.92,
        response_time_ms=1800
    )
    assert 0.05 <= prob_high <= 0.99
    print(f"✓ Rapid recall probability: {prob_high:.2f}")

    adj_int, reason = spaced_repetition_ml.adjust_interval(
        sm2_interval=10,
        rating=4,
        recall_probability=prob_high,
        response_time_ms=1800
    )
    print(f"✓ Adjusted interval: {adj_int} days ({reason})")

def test_flashcard_endpoints():
    print("\nTesting FastAPI Flashcard endpoints...")
    test_student = "student001"

    # 1. Seed or fetch cards
    res = client.get(f"/api/flashcards/{test_student}")
    assert res.status_code == 200, res.text
    cards = res.json()
    print(f"✓ Fetched {len(cards)} cards for {test_student}")
    assert len(cards) > 0
    card_id = cards[0]["id"]

    # 2. Review a card
    res = client.post(f"/api/flashcards/{test_student}/review", json={
        "flashcard_id": card_id,
        "rating": 3,
        "response_time_ms": 2800
    })
    assert res.status_code == 200, res.text
    review_data = res.json()
    assert "ml_adjusted_interval" in review_data
    assert "predicted_recall_probability" in review_data
    print(f"✓ Review submitted. ML recall probability: {review_data['predicted_recall_probability']}, new interval: {review_data['ml_adjusted_interval']}d")

    # 3. Topic generation
    res = client.post(f"/api/flashcards/{test_student}/generate", json={
        "topic": "DBMS Indexing",
        "notes": "B+ Trees store records in leaf nodes and use fan-out keys for high index efficiency.",
        "count": 2
    })
    assert res.status_code == 200, res.text
    new_cards = res.json()
    assert len(new_cards) == 2
    print(f"✓ Generated {len(new_cards)} topic cards for 'DBMS Indexing'")

    # 4. Predict interval
    res = client.post(f"/api/flashcards/{test_student}/predict-interval", json={
        "previous_interval": 3,
        "ease_factor": 2.5,
        "repetitions": 2,
        "historical_accuracy": 0.85,
        "response_time_ms": 2400,
        "rating": 4
    })
    assert res.status_code == 200, res.text
    pred = res.json()
    print(f"✓ ML inference endpoint: recall prob={pred['predicted_recall_probability']}, suggested interval={pred['suggested_interval']}d")

    # 5. Stats
    res = client.get(f"/api/flashcards/{test_student}/stats")
    assert res.status_code == 200, res.text
    stats = res.json()
    print(f"✓ Deck stats: Total={stats['total_cards']}, Due={stats['due_cards']}, Retention={stats['retention_rate']*100}%")

if __name__ == "__main__":
    test_sm2_calculations()
    test_ml_pipeline()
    test_flashcard_endpoints()
    print("\n🎉 ALL SPACED REPETITION FLASHCARD TESTS PASSED!")
