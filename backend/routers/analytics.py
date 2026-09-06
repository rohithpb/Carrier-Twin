from fastapi import APIRouter
from typing import Dict, Any, List
from collections import Counter
from services.firebase_service import db_service

router = APIRouter(prefix="/api/placement", tags=["Placement Analytics"])

@router.get("/analytics", response_model=Dict[str, Any])
def get_placement_analytics():
    """
    Return placement dashboard batch analytics:
    Total Students, Job Ready, Nearly Ready, Developing, At Risk,
    Top Skill Gaps, Top Career Roles, Department-wise Readiness, Year-wise Readiness.
    """
    students = db_service.get_all_students()
    total_students = len(students)

    job_ready = 0
    nearly_ready = 0
    developing = 0
    at_risk = 0

    all_skill_gaps = []
    target_roles = []
    dept_readiness: Dict[str, List[int]] = {}
    year_readiness: Dict[int, List[int]] = {}

    for s in students:
        readiness = s.get("career_readiness", 50)
        status = s.get("status", "")
        dept = s.get("department", "Computer Science")
        year = s.get("current_year", 2)
        role = s.get("target_role", "Software Engineer")
        gaps = s.get("skill_gap", [])

        if readiness >= 81 or status == "Job Ready":
            job_ready += 1
        elif readiness >= 61 or status == "Nearly Ready":
            nearly_ready += 1
        elif readiness >= 41 or status == "Developing":
            developing += 1
        else:
            at_risk += 1

        all_skill_gaps.extend(gaps)
        target_roles.append(role)

        dept_readiness.setdefault(dept, []).append(readiness)
        year_readiness.setdefault(year, []).append(readiness)

    # Top skill gaps
    gap_counts = Counter(all_skill_gaps)
    top_skill_gaps = [gap for gap, count in gap_counts.most_common(6)]

    # Top target roles
    role_counts = Counter(target_roles)
    top_roles = [role for role, count in role_counts.most_common(5)]

    # Average readiness by department
    dept_avg = {
        dept: round(sum(scores) / len(scores), 1)
        for dept, scores in dept_readiness.items()
    }

    # Average readiness by year
    year_avg = {
        str(year): round(sum(scores) / len(scores), 1)
        for year, scores in sorted(year_readiness.items())
    }

    return {
        "total_students": total_students,
        "job_ready": job_ready,
        "nearly_ready": nearly_ready,
        "developing": developing,
        "at_risk": at_risk,
        "top_skill_gaps": top_skill_gaps if top_skill_gaps else ["AWS", "Power BI", "Docker", "SQL"],
        "top_target_roles": top_roles,
        "department_readiness": dept_avg,
        "year_readiness": year_avg
    }
