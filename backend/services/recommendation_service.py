from typing import Dict, Any, List
from services.firebase_service import db_service

class RecommendationService:
    @staticmethod
    def get_recommendations_for_student(student_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        opportunities = db_service.get_all_opportunities()
        student_year = student_data.get("current_year", 2)
        target_role = student_data.get("target_role", "").lower()
        target_industry = student_data.get("target_industry", "").lower()
        student_skills = [s.lower() for s in student_data.get("skills", [])]
        skill_gaps = [g.lower() for g in student_data.get("skill_gap", [])]

        recommendations = []

        for opp in opportunities:
            reasons = []

            # 1. Eligibility Check (Year)
            eligible_years = opp.get("eligible_year", [1, 2, 3, 4])
            if student_year in eligible_years:
                year_score = 15
            else:
                year_score = 0

            # 2. Role & Industry Match (30%)
            opp_role = opp.get("job_role", "").lower()
            opp_ind = opp.get("industry", "").lower()
            if target_role and target_role in opp_role:
                role_score = 30
                reasons.append(f"Matches target role ({opp.get('job_role')})")
            elif target_industry and target_industry in opp_ind:
                role_score = 20
                reasons.append(f"Matches target industry ({opp.get('industry')})")
            else:
                role_score = 10

            # 3. Skill Match (40%)
            opp_skills = [s.lower() for s in opp.get("required_skills", [])]
            matched_skills = [s for s in opp_skills if s in student_skills]
            if opp_skills:
                skill_score = int((len(matched_skills) / len(opp_skills)) * 40)
            else:
                skill_score = 20

            if matched_skills:
                reasons.append(f"Matches skills: {', '.join([s.capitalize() for s in matched_skills])}")

            # 4. Skill Gap Relevance (10%)
            gap_matches = [s for s in opp_skills if s in skill_gaps]
            if gap_matches:
                gap_score = 10
                reasons.append(f"Addresses priority skill gap: {', '.join([s.capitalize() for s in gap_matches])}")
            else:
                gap_score = 0

            # 5. Interest Match (5%)
            interest_score = 5

            total_match = year_score + role_score + skill_score + gap_score + interest_score
            total_match = min(99, max(40, total_match))

            if not reasons:
                reasons.append("Relevant career development opportunity")

            recommendations.append({
                "id": opp.get("id"),
                "title": opp.get("title"),
                "organization": opp.get("organization"),
                "type": opp.get("type"),
                "match_score": total_match,
                "reasons": reasons,
                "deadline": opp.get("deadline"),
                "mode": opp.get("mode"),
                "job_role": opp.get("job_role")
            })

        # Sort by match score descending
        recommendations.sort(key=lambda x: x["match_score"], reverse=True)
        return recommendations[:10]

    @staticmethod
    def get_next_best_action(student_data: Dict[str, Any]) -> Dict[str, Any]:
        skill_gaps = student_data.get("skill_gap", [])
        recommendations = RecommendationService.get_recommendations_for_student(student_data)

        if skill_gaps:
            top_gap = skill_gaps[0]
            # Search recommendations for an opportunity addressing top_gap
            for rec in recommendations:
                reasons = " ".join(rec.get("reasons", [])).lower()
                if top_gap.lower() in reasons or top_gap.lower() in rec.get("title", "").lower():
                    return {
                        "title": rec.get("title"),
                        "reason": f"Completing this {rec.get('type', 'activity').lower()} will close your highest priority skill gap in {top_gap}.",
                        "priority": "HIGH",
                        "opportunity_id": rec.get("id"),
                        "target_skill": top_gap
                    }

        # Fallback default next best action
        if recommendations:
            top_rec = recommendations[0]
            return {
                "title": top_rec.get("title"),
                "reason": f"Recommended based on your target role ({student_data.get('target_role', 'Software Engineer')}) and current roadmap progress.",
                "priority": "HIGH",
                "opportunity_id": top_rec.get("id"),
                "target_skill": student_data.get("target_role")
            }

        return {
            "title": "Complete a Power BI Workshop",
            "reason": "Completing this workshop will reduce your highest priority skill gap.",
            "priority": "HIGH"
        }

recommendation_service = RecommendationService()
