from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from services.firebase_service import db_service
from services.readiness_service import readiness_service
from services.recommendation_service import recommendation_service
from schemas.student import AddActivityRequest

router = APIRouter(prefix="/api/students", tags=["Students"])

@router.get("", response_model=List[Dict[str, Any]])
def get_all_students():
    """Return all demo students."""
    return db_service.get_all_students()

@router.get("/{student_id}", response_model=Dict[str, Any])
def get_student_by_id(student_id: str):
    """Return the complete Student Digital Twin profile."""
    student = db_service.get_student_by_id(student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student with ID '{student_id}' not found.")
    return student

@router.get("/{student_id}/skills", response_model=Dict[str, Any])
def get_student_skills(student_id: str):
    """Return student skills and skill levels."""
    student = db_service.get_student_by_id(student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student with ID '{student_id}' not found.")
    return {
        "student_id": student_id,
        "skills": student.get("skills", []),
        "skill_levels": student.get("skill_levels", {}),
        "skill_gap": student.get("skill_gap", [])
    }

@router.get("/{student_id}/activities", response_model=List[Dict[str, Any]])
def get_student_activities(student_id: str):
    """Return student activities (MOOCs, Workshops, Internships, Projects, Certifications, Hackathons)."""
    student = db_service.get_student_by_id(student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student with ID '{student_id}' not found.")
    return student.get("activities", [])

@router.get("/{student_id}/readiness", response_model=Dict[str, Any])
def get_student_readiness(student_id: str):
    """Return Career Readiness Score, category, breakdown, and missing skills."""
    student = db_service.get_student_by_id(student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student with ID '{student_id}' not found.")
    return readiness_service.calculate_readiness(student)

@router.post("/{student_id}/activities", response_model=Dict[str, Any])
def add_student_activity(student_id: str, req: AddActivityRequest):
    """
    Add a new activity to student profile.
    Automatically recalculates readiness score, skills, and recommendations.
    """
    student = db_service.get_student_by_id(student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student with ID '{student_id}' not found.")

    activities = student.get("activities", [])
    new_act_id = f"act_{len(activities) + 1:02d}"
    new_activity = {
        "id": new_act_id,
        "title": req.title,
        "type": req.type.upper(),
        "score": req.score or 85,
        "date": req.date or "2026-09-05"
    }
    activities.append(new_activity)
    student["activities"] = activities

    # Update skills if provided
    if req.skills_covered:
        skills = student.get("skills", [])
        skill_levels = student.get("skill_levels", {})
        for s in req.skills_covered:
            if s not in skills:
                skills.append(s)
            skill_levels[s] = min(100, skill_levels.get(s, 50) + 15)
        student["skills"] = skills
        student["skill_levels"] = skill_levels

        # Update skill gap
        skill_gap = student.get("skill_gap", [])
        student["skill_gap"] = [g for g in skill_gap if g.lower() not in [sc.lower() for sc in req.skills_covered]]

    # Recalculate readiness
    readiness_data = readiness_service.calculate_readiness(student)
    student["career_readiness"] = readiness_data["career_readiness_score"]
    student["status"] = readiness_data["readiness_category"]

    db_service.update_student(student_id, student)

    return {
        "message": "Activity added successfully.",
        "activity": new_activity,
        "updated_career_readiness": student["career_readiness"],
        "status": student["status"]
    }

@router.get("/{student_id}/digital-twin", response_model=Dict[str, Any])
def get_digital_twin(student_id: str):
    """
    Return the Digital Twin complete view for student.
    Includes Profile, Academic Progress, Skills, Target Role, Skill Gap, Readiness, Next Best Action.
    """
    student = db_service.get_student_by_id(student_id)
    if not student:
        raise HTTPException(status_code=404, detail=f"Student with ID '{student_id}' not found.")

    readiness = readiness_service.calculate_readiness(student)
    next_action = recommendation_service.get_next_best_action(student)

    return {
        "student": student.get("name"),
        "student_id": student.get("id"),
        "department": student.get("department"),
        "batch": student.get("batch"),
        "current_year": student.get("current_year"),
        "cgpa": student.get("cgpa"),
        "target_industry": student.get("target_industry"),
        "target_role": student.get("target_role"),
        "skills": student.get("skill_levels", {}),
        "skill_gap": student.get("skill_gap", []),
        "career_readiness": readiness["career_readiness_score"],
        "readiness_category": readiness["readiness_category"],
        "next_best_action": next_action,
        "completed_activities": student.get("activities", []),
        "academic_progress": {
            "current_semester": student.get("current_semester"),
            "cgpa": student.get("cgpa"),
            "status": student.get("status")
        }
    }
