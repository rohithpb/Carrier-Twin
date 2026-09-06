from pydantic import BaseModel
from typing import List, Optional

class RecruiterSchema(BaseModel):
    id: str
    name: str
    email: str
    company: str
    designation: str
    target_role: str
    required_skills: List[str]
    min_match_score: int

class RecruiterMatchRequest(BaseModel):
    job_role: str
    required_skills: List[str]
    min_match_score: Optional[int] = 60

class CandidateMatch(BaseModel):
    student_id: str
    student: str
    department: str
    batch: str
    match_score: int
    career_readiness: int
    matching_skills: List[str]
    skill_gaps: List[str]
    cgpa: float

class RecruiterMatchResponse(BaseModel):
    candidates: List[CandidateMatch]
