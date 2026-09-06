from pydantic import BaseModel
from typing import List, Optional

class OpportunitySchema(BaseModel):
    id: str
    title: str
    organization: str
    description: str
    type: str  # INTERNSHIP, WORKSHOP, MOOC, HACKATHON, CERTIFICATION, TRAINING, JOB
    industry: str
    job_role: str
    required_skills: List[str]
    eligible_year: List[int]
    mode: str
    location: str
    deadline: str
    status: str
