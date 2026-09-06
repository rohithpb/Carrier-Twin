from pydantic import BaseModel
from typing import List, Optional, Any

class OpportunityRecommendation(BaseModel):
    id: str
    title: str
    organization: str
    type: str
    match_score: int
    reasons: List[str]
    deadline: str
    mode: str

class NextBestActionResponse(BaseModel):
    title: str
    reason: str
    priority: str
    opportunity_id: Optional[str] = None
    target_skill: Optional[str] = None

class RecommendedRole(BaseModel):
    role: str
    confidence: int

class CareerPredictionResponse(BaseModel):
    student_id: str
    predicted_roles: List[RecommendedRole]
    model_source: str  # "ML Model (.pkl)" or "Rule-based Engine"
