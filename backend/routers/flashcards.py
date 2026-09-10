from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional, Dict, Any

from schemas.flashcard import (
    FlashcardCreate,
    FlashcardResponse,
    ReviewRequest,
    ReviewResponse,
    PredictIntervalRequest,
    PredictIntervalResponse,
    GenerateFlashcardsRequest,
    FlashcardStatsResponse,
)
from services.flashcard_service import flashcard_service
from services.flashcard_generation_service import flashcard_generator
from services.spaced_repetition_ml import spaced_repetition_ml
from services.sm2_service import sm2_service

router = APIRouter(prefix="/api/flashcards", tags=["Spaced Repetition Flashcards"])

@router.get("/{student_id}", response_model=List[FlashcardResponse])
def get_flashcards(
    student_id: str,
    due_only: bool = Query(False, description="Filter only cards due for review today"),
    tag: Optional[str] = Query(None, description="Filter by course topic or skill node")
):
    """Retrieve flashcards for a student, optionally filtered by due status or topic tag."""
    return flashcard_service.get_flashcards(student_id, due_only=due_only, tag=tag)

@router.post("/{student_id}", response_model=FlashcardResponse)
def create_flashcard(student_id: str, req: FlashcardCreate):
    """Create a new flashcard for a specific student."""
    card = flashcard_service.create_flashcard(
        student_id=student_id,
        front=req.front,
        back=req.back,
        tag=req.tag
    )
    return card

@router.post("/{student_id}/review", response_model=ReviewResponse)
def review_flashcard(student_id: str, req: ReviewRequest):
    """
    Submit Anki spaced repetition review for a card.
    Updates repetitions, ease factor, interval, and next due date using SM-2 + ML adjustments.
    Logs telemetry into the review_logs collection.
    """
    result = flashcard_service.review_card(
        student_id=student_id,
        card_id=req.flashcard_id,
        rating=req.rating,
        response_time_ms=req.response_time_ms
    )
    if not result:
        raise HTTPException(status_code=404, detail=f"Flashcard '{req.flashcard_id}' not found for student '{student_id}'.")
    return result

@router.post("/{student_id}/generate", response_model=List[FlashcardResponse])
async def generate_topic_flashcards(student_id: str, req: GenerateFlashcardsRequest):
    """
    Topic-Specific Flashcard Generation endpoint.
    Uses LLM (NVIDIA NIM / Gemini / OpenAI) or knowledge engine to parse course topics/notes
    and save generated Anki pairs directly into the student's flashcards collection.
    """
    raw_cards = await flashcard_generator.generate_cards(
        topic=req.topic,
        notes=req.notes,
        count=req.count
    )

    created_cards = []
    for c in raw_cards:
        card = flashcard_service.create_flashcard(
            student_id=student_id,
            front=c["front"],
            back=c["back"],
            tag=c.get("tag", req.topic)
        )
        created_cards.append(card)

    return created_cards

@router.post("/{student_id}/predict-interval", response_model=PredictIntervalResponse)
def predict_interval(student_id: str, req: PredictIntervalRequest):
    """
    ML Inference endpoint predicting recall probability and suggested interval
    given telemetry and prior review history.
    """
    prob = spaced_repetition_ml.predict_recall_probability(
        previous_interval=req.previous_interval,
        ease_factor=req.ease_factor,
        repetitions=req.repetitions,
        historical_accuracy=req.historical_accuracy,
        response_time_ms=req.response_time_ms
    )

    sm2_res = sm2_service.calculate(
        rating=req.rating or 3,
        current_interval=req.previous_interval,
        current_ease_factor=req.ease_factor,
        current_repetitions=req.repetitions
    )

    adjusted_interval, reason = spaced_repetition_ml.adjust_interval(
        sm2_interval=sm2_res["interval"],
        rating=req.rating or 3,
        recall_probability=prob,
        response_time_ms=req.response_time_ms
    )

    return {
        "predicted_recall_probability": round(prob, 2),
        "suggested_interval": adjusted_interval,
        "confidence": round(prob if prob >= 0.5 else 1.0 - prob, 2),
        "explanation": reason
    }

@router.get("/{student_id}/stats", response_model=FlashcardStatsResponse)
def get_flashcard_stats(student_id: str):
    """Fetch mastery metrics, due cards, retention rates, and topic breakdown."""
    return flashcard_service.get_stats(student_id)

@router.post("/{student_id}/seed", response_model=List[FlashcardResponse])
def seed_flashcards(student_id: str):
    """Seed curriculum flashcards for immediate testing."""
    return flashcard_service.seed_default_cards(student_id)
