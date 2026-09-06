from pydantic import BaseModel
from typing import List, Optional

class MentorSchema(BaseModel):
    id: str
    name: str
    email: str
    department: str
    designation: str
    assigned_class: str
    assigned_student_ids: List[str]

class MentorAnalyticsResponse(BaseModel):
    mentor_id: str
    total_students: int
    on_track: int
    needs_attention: int
    at_risk: int
    average_readiness: float
