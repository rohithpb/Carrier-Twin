from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any

class FlashcardBase(BaseModel):
    front: str = Field(..., description="Front of the card (question/concept prompt)")
    back: str = Field(..., description="Back of the card (answer, explanation, key takeaways)")
    tag: str = Field("General", description="Topic or skill node ID (e.g. DBMS, Python, OS)")

class FlashcardCreate(FlashcardBase):
    pass

class FlashcardResponse(FlashcardBase):
    id: str
    student_id: str
    interval: int = Field(1, description="Interval in days until next review")
    easeFactor: float = Field(2.5, description="Anki Ease Factor (default 2.5)")
    repetitions: int = Field(0, description="Consecutive successful recall reviews")
    dueDate: str = Field(..., description="ISO 8601 formatted due date")
    lastResponseTimeMs: int = Field(0, description="Elapsed milliseconds during last review")
    created_at: str

class ReviewRequest(BaseModel):
    flashcard_id: str
    rating: int = Field(..., ge=1, le=4, description="Anki rating: 1=Again, 2=Hard, 3=Good, 4=Easy")
    response_time_ms: int = Field(..., ge=0, description="Student response latency in milliseconds")

class ReviewResponse(BaseModel):
    flashcard: FlashcardResponse
    sm2_interval: int
    ml_adjusted_interval: int
    predicted_recall_probability: float
    interval_adjustment_reason: str
    ease_factor_change: float

class PredictIntervalRequest(BaseModel):
    previous_interval: int
    ease_factor: float
    repetitions: int
    historical_accuracy: float
    response_time_ms: int
    rating: Optional[int] = 3

class PredictIntervalResponse(BaseModel):
    predicted_recall_probability: float
    suggested_interval: int
    confidence: float
    explanation: str

class GenerateFlashcardsRequest(BaseModel):
    topic: str = Field(..., description="Course topic or skill node e.g. DBMS Normalization")
    course_id: Optional[str] = None
    notes: Optional[str] = Field(None, description="Optional lecture notes or textbook excerpt")
    count: int = Field(5, ge=1, le=15, description="Number of flashcards to generate")

class FlashcardStatsResponse(BaseModel):
    total_cards: int
    due_cards: int
    retention_rate: float
    average_response_time_ms: int
    topics: List[str]
    cards_by_topic: Dict[str, int]
