from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any

class ActivityItem(BaseModel):
    id: Optional[str] = None
    title: str
    type: str  # MOOC, WORKSHOP, INTERNSHIP, PROJECT, CERTIFICATION, HACKATHON
    score: Optional[int] = 80
    date: Optional[str] = None

class AddActivityRequest(BaseModel):
    title: str
    type: str
    score: Optional[int] = 80
    date: Optional[str] = None
    skills_covered: Optional[List[str]] = []

class StudentProfileSchema(BaseModel):
    id: str
    name: str
    email: str
    department: str
    batch: str
    current_year: int
    current_semester: int
    cgpa: float
    target_industry: str
    target_role: str
    skills: List[str]
    skill_levels: Dict[str, int]
    activities: List[ActivityItem] = []
    career_readiness: int
    status: str
    skill_gap: List[str] = []

class ReadinessBreakdown(BaseModel):
    academic_score: float
    academic_max: float = 20.0
    technical_skills_score: float
    technical_skills_max: float = 30.0
    moocs_score: float
    moocs_max: float = 15.0
    projects_score: float
    projects_max: float = 15.0
    internships_score: float
    internships_max: float = 10.0
    workshops_score: float
    workshops_max: float = 5.0
    placement_prep_score: float
    placement_prep_max: float = 5.0

class ReadinessResponse(BaseModel):
    student_id: str
    career_readiness_score: int
    readiness_category: str
    score_breakdown: ReadinessBreakdown
    missing_skills: List[str]

class DigitalTwinResponse(BaseModel):
    student: str
    student_id: str
    target_role: str
    skills: Dict[str, int]
    skill_gap: List[str]
    career_readiness: int
    readiness_category: str
    next_best_action: Any
    academic_progress: Dict[str, Any]
    completed_activities: List[ActivityItem]
