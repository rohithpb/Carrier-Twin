from fastapi import APIRouter, HTTPException
from typing import Dict, Any, List
from pydantic import BaseModel
from services.firebase_service import db_service
from services.model_service import model_service
from services.recommendation_service import recommendation_service

router = APIRouter(tags=["Recommendations & AI Predictions"])

class PredictCareerRequest(BaseModel):
    student_id: str

@router.get("/api/students/{student_id}/recommendations", response_model=Dict[str, Any])
def get_student_recommendations(student_id: str):
    """
    Return top 10 recommended opportunities for student based on match score and skill gaps.
    """
    student = db_service.get_student_by_id(student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student with ID '{student_id}' not found.")

    recs = recommendation_service.get_recommendations_for_student(student)
    next_action = recommendation_service.get_next_best_action(student)

    return {
        "student_id": student_id,
        "recommendations": recs,
        "next_best_action": next_action
    }

@router.post("/api/predict-career", response_model=Dict[str, Any])
def predict_career(req: PredictCareerRequest):
    """
    Predict suitable career roles for a student using loaded pickle ML model if available,
    otherwise falling back seamlessly to the rule-based prediction engine.
    """
    student = db_service.get_student_by_id(req.student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student with ID '{req.student_id}' not found.")

    predictions = model_service.predict_career(student)
    source = "ML Model (.pkl)" if model_service.ml_mode else "Rule-based Engine"

    return {
        "student_id": req.student_id,
        "predicted_roles": predictions,
        "model_source": source
    }
