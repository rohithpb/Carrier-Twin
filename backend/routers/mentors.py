from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from services.firebase_service import db_service
from services.readiness_service import readiness_service

router = APIRouter(prefix="/api/mentors", tags=["Mentors"])

@router.get("/{mentor_id}/students", response_model=List[Dict[str, Any]])
def get_mentor_students(mentor_id: str):
    """Return assigned students for a mentor."""
    mentor = db_service.get_mentor_by_id(mentor_id)
    if not mentor:
        raise HTTPException(status_code=404, detail=f"Mentor with ID '{mentor_id}' not found.")

    assigned_ids = mentor.get("assigned_student_ids", [])
    all_students = db_service.get_all_students()

    assigned_students = [s for s in all_students if s.get("id") in assigned_ids]
    
    # Enhance each student with risk level
    for s in assigned_students:
        readiness = s.get("career_readiness", 50)
        gaps = s.get("skill_gap", [])
        if readiness < 40 or len(gaps) >= 3:
            s["risk_level"] = "HIGH"
        elif readiness < 60 or len(gaps) >= 2:
            s["risk_level"] = "MEDIUM"
        else:
            s["risk_level"] = "LOW"

    return assigned_students

@router.get("/{mentor_id}/analytics", response_model=Dict[str, Any])
def get_mentor_analytics(mentor_id: str):
    """Return mentor dashboard analytics: total_students, on_track, needs_attention, at_risk, average_readiness."""
    students = get_mentor_students(mentor_id)
    if not students:
        # Return summary across all students if mentor specific list is empty
        students = db_service.get_all_students()

    total = len(students)
    if total == 0:
        return {
            "mentor_id": mentor_id,
            "total_students": 0,
            "on_track": 0,
            "needs_attention": 0,
            "at_risk": 0,
            "average_readiness": 0.0
        }

    on_track = 0
    needs_attention = 0
    at_risk = 0
    total_readiness = 0

    for s in students:
        readiness = s.get("career_readiness", 50)
        total_readiness += readiness

        if readiness >= 70:
            on_track += 1
        elif readiness >= 40:
            needs_attention += 1
        else:
            at_risk += 1

    return {
        "mentor_id": mentor_id,
        "total_students": total,
        "on_track": on_track,
        "needs_attention": needs_attention,
        "at_risk": at_risk,
        "average_readiness": round(total_readiness / total, 1)
    }
