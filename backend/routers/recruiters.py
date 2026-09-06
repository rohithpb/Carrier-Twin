from fastapi import APIRouter, HTTPException
from typing import Dict, Any, List
from services.firebase_service import db_service
from schemas.recruiter import RecruiterMatchRequest, RecruiterMatchResponse, CandidateMatch

router = APIRouter(prefix="/api/recruiters", tags=["Recruiters"])

@router.post("/{recruiter_id}/match-students", response_model=RecruiterMatchResponse)
def match_candidates_for_recruiter(recruiter_id: str, req: RecruiterMatchRequest):
    """
    Search and match demo students based on Job Role, Required Skills, and Minimum Match Score.
    Returns ranked student candidates.
    """
    all_students = db_service.get_all_students()
    req_skills_lower = [s.lower() for s in req.required_skills]
    target_role_lower = req.job_role.lower()

    candidates: List[CandidateMatch] = []

    for s in all_students:
        s_skills_lower = [sk.lower() for sk in s.get("skills", [])]
        s_role_lower = s.get("target_role", "").lower()

        # Skill Match Score (50%)
        matching_skills = [sk for sk in s.get("skills", []) if sk.lower() in req_skills_lower]
        if req_skills_lower:
            skill_score = (len(matching_skills) / len(req_skills_lower)) * 50.0
        else:
            skill_score = 30.0

        # Role Match Score (30%)
        if target_role_lower in s_role_lower or s_role_lower in target_role_lower:
            role_score = 30.0
        else:
            role_score = 15.0

        # Readiness Weight (20%)
        readiness = s.get("career_readiness", 50)
        readiness_score = (readiness / 100.0) * 20.0

        total_match = int(round(skill_score + role_score + readiness_score))
        total_match = min(99, max(30, total_match))

        min_cutoff = req.min_match_score or 60
        if total_match >= min_cutoff:
            candidates.append(CandidateMatch(
                student_id=s.get("id", ""),
                student=s.get("name", ""),
                department=s.get("department", ""),
                batch=s.get("batch", ""),
                match_score=total_match,
                career_readiness=readiness,
                matching_skills=matching_skills,
                skill_gaps=s.get("skill_gap", []),
                cgpa=s.get("cgpa", 7.0)
            ))

    # Sort candidates by match score descending
    candidates.sort(key=lambda c: c.match_score, reverse=True)

    return RecruiterMatchResponse(candidates=candidates)
