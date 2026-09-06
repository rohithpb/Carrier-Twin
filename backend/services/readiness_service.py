from typing import Dict, Any, List, Tuple

class ReadinessService:
    @staticmethod
    def calculate_readiness(student_data: Dict[str, Any]) -> Dict[str, Any]:
        cgpa = float(student_data.get("cgpa", 7.0))
        skill_levels = student_data.get("skill_levels", {})
        activities = student_data.get("activities", [])

        # 1. Academic Performance (Max 20 pts)
        academic_score = min(20.0, round((cgpa / 10.0) * 20.0, 1))

        # 2. Technical Skills (Max 30 pts)
        if skill_levels:
            avg_skill = sum(skill_levels.values()) / len(skill_levels)
            tech_score = min(30.0, round((avg_skill / 100.0) * 30.0, 1))
        else:
            tech_score = 10.0

        # 3. MOOCs & Certifications (Max 15 pts)
        moocs = [a for a in activities if a.get("type") in ["MOOC", "CERTIFICATION"]]
        mooc_score = min(15.0, round(len(moocs) * 5.0, 1))

        # 4. Projects & Hackathons (Max 15 pts)
        projects = [a for a in activities if a.get("type") in ["PROJECT", "HACKATHON"]]
        project_score = min(15.0, round(len(projects) * 7.5, 1))

        # 5. Internships (Max 10 pts)
        internships = [a for a in activities if a.get("type") == "INTERNSHIP"]
        internship_score = min(10.0, round(len(internships) * 10.0, 1))

        # 6. Workshops & Activities (Max 5 pts)
        workshops = [a for a in activities if a.get("type") in ["WORKSHOP", "TRAINING"]]
        workshop_score = min(5.0, round(len(workshops) * 2.5, 1))

        # 7. Placement Prep (Max 5 pts)
        placement_score = 3.5 if cgpa >= 7.5 else 2.0

        total_score = int(round(
            academic_score + tech_score + mooc_score + project_score +
            internship_score + workshop_score + placement_score
        ))
        total_score = min(100, max(0, total_score))

        # Readiness Category
        if total_score <= 40:
            category = "Needs Development"
        elif total_score <= 60:
            category = "Developing"
        elif total_score <= 80:
            category = "Nearly Ready"
        else:
            category = "Job Ready"

        score_breakdown = {
            "academic_score": academic_score,
            "academic_max": 20.0,
            "technical_skills_score": tech_score,
            "technical_skills_max": 30.0,
            "moocs_score": mooc_score,
            "moocs_max": 15.0,
            "projects_score": project_score,
            "projects_max": 15.0,
            "internships_score": internship_score,
            "internships_max": 10.0,
            "workshops_score": workshop_score,
            "workshops_max": 5.0,
            "placement_prep_score": placement_score,
            "placement_prep_max": 5.0,
        }

        missing_skills = student_data.get("skill_gap", [])

        return {
            "student_id": student_data.get("id", ""),
            "career_readiness_score": total_score,
            "readiness_category": category,
            "score_breakdown": score_breakdown,
            "missing_skills": missing_skills,
        }

readiness_service = ReadinessService()
