import os
from typing import Dict, Any, List, Optional
from services.firebase_service import db_service
from services.readiness_service import readiness_service
from schemas.chat import ChatMessage, ChatResponse

class ChatService:
    def __init__(self):
        self.model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

    def get_student_context(self, student_id: str) -> Dict[str, Any]:
        """Fetch student profile and calculate readiness breakdown."""
        student = db_service.get_student_by_id(student_id)
        if not student:
            # Fallback to student001 if specific ID is not found in demo data
            student = db_service.get_student_by_id("student001") or {}

        readiness = readiness_service.calculate_readiness(student) if student else {}
        
        name = student.get("name", "Student")
        department = student.get("department", "Engineering")
        batch = student.get("batch", "2023-2027")
        current_year = student.get("current_year", 2)
        cgpa = student.get("cgpa", 8.0)
        target_role = student.get("target_role", "Software Engineer")
        target_industry = student.get("target_industry", "Technology")
        skills = student.get("skills", [])
        skill_levels = student.get("skill_levels", {})
        activities = student.get("activities", [])
        
        readiness_score = readiness.get("career_readiness_score", 50)
        readiness_category = readiness.get("readiness_category", "Developing")
        score_breakdown = readiness.get("score_breakdown", {})
        missing_skills = readiness.get("missing_skills", [])

        return {
            "student_id": student_id,
            "name": name,
            "department": department,
            "batch": batch,
            "current_year": current_year,
            "cgpa": cgpa,
            "target_role": target_role,
            "target_industry": target_industry,
            "skills": skills,
            "skill_levels": skill_levels,
            "activities_count": len(activities),
            "activities": activities[:5],
            "career_readiness_score": readiness_score,
            "readiness_category": readiness_category,
            "score_breakdown": score_breakdown,
            "missing_skills": missing_skills
        }

    def build_system_prompt(self, ctx: Dict[str, Any]) -> str:
        """Construct an empathetic, expert career coaching system prompt with injected digital twin context."""
        skills_str = ", ".join([f"{k} ({v}%)" for k, v in ctx["skill_levels"].items()]) if ctx["skill_levels"] else "None listed"
        missing_str = ", ".join(ctx["missing_skills"]) if ctx["missing_skills"] else "None detected"
        
        breakdown = ctx.get("score_breakdown", {})
        breakdown_str = (
            f"Academic: {breakdown.get('academic_score', 0)}/20, "
            f"Technical Skills: {breakdown.get('technical_skills_score', 0)}/30, "
            f"MOOCs: {breakdown.get('moocs_score', 0)}/15, "
            f"Projects: {breakdown.get('projects_score', 0)}/15, "
            f"Internships: {breakdown.get('internships_score', 0)}/10, "
            f"Workshops: {breakdown.get('workshops_score', 0)}/5, "
            f"Placement Prep: {breakdown.get('placement_prep_score', 0)}/5"
        )

        return f"""You are the CareerTwin AI Career Coach — an expert, perceptive, empathetic, and pragmatic career advisor for university students.
You have direct, real-time access to this student's Educational Digital Twin profile:

=== STUDENT DIGITAL TWIN PROFILE ===
- Name: {ctx['name']}
- Department: {ctx['department']} (Year {ctx['current_year']}, Batch {ctx['batch']})
- Current CGPA: {ctx['cgpa']}
- Target Career Role: {ctx['target_role']} (Industry: {ctx['target_industry']})
- Current Skills & Proficiency: {skills_str}
- Missing Skill Gaps: {missing_str}
- Career Readiness Score: {ctx['career_readiness_score']}/100 ({ctx['readiness_category']})
- 7-Pillar Breakdown: {breakdown_str}
- Completed Activities Recorded: {ctx['activities_count']}
====================================

COACHING GUIDELINES:
1. Speak warmly, encouragingly, and authoritatively, like a dedicated campus mentor sitting across the table.
2. Directly reference their specific profile metrics (their actual target role "{ctx['target_role']}", CGPA, top skills, and identified skill gaps like {missing_str}).
3. When answering questions, provide structured, highly actionable steps (e.g. specific project architectures, certification topics, daily study routines, LeetCode/portfolio tips).
4. If they ask about raising their readiness score, analyze their lowest pillars in the 7-pillar breakdown and give concrete recommendations to gain points.
5. Format your response cleanly using markdown (bullet points, bold key terms). Keep answers focused, motivating, and easy to read.
"""

    def call_gemini(self, system_prompt: str, message: str, chat_history: List[ChatMessage]) -> Optional[str]:
        """Invoke Google GenAI SDK if API key is configured."""
        api_key = os.getenv("GEMINI_API_KEY", "").strip()
        if not api_key:
            return None

        try:
            from google import genai
            from google.genai import types

            client = genai.Client(api_key=api_key)

            # Build multi-turn history contents
            contents = []
            for item in chat_history:
                role = "model" if item.role in ["model", "assistant"] else "user"
                contents.append(types.Content(
                    role=role,
                    parts=[types.Part.from_text(text=item.content)]
                ))
            
            # Append latest user message
            contents.append(types.Content(
                role="user",
                parts=[types.Part.from_text(text=message)]
            ))

            config = types.GenerateContentConfig(
                system_instruction=system_prompt,
                temperature=0.7,
                max_output_tokens=1024,
            )

            response = client.models.generate_content(
                model=self.model_name,
                contents=contents,
                config=config
            )
            return response.text
        except Exception as e:
            print(f"[ChatService] Gemini API call error: {e}. Switching to heuristic fallback.")
            return None

    def generate_fallback_response(self, ctx: Dict[str, Any], message: str) -> str:
        """
        Smart, profile-aware rule-based fallback when Gemini API key is not present or offline.
        Ensures the application always provides high-value, tailored career advice without failing.
        """
        msg_lower = message.lower()
        name = ctx["name"]
        target = ctx["target_role"]
        gaps = ctx["missing_skills"]
        gaps_str = ", ".join(gaps) if gaps else "advanced portfolio projects"
        score = ctx["career_readiness_score"]
        category = ctx["readiness_category"]
        breakdown = ctx.get("score_breakdown", {})

        # Low score pillar check
        low_pillars = []
        if breakdown.get("projects_score", 0) < 10:
            low_pillars.append("Hands-on Projects (currently at {:.1f}/15)".format(breakdown.get("projects_score", 0)))
        if breakdown.get("internships_score", 0) < 5:
            low_pillars.append("Industry Internships (currently at {:.1f}/10)".format(breakdown.get("internships_score", 0)))
        if breakdown.get("moocs_score", 0) < 10:
            low_pillars.append("MOOCs & NPTEL Certifications (currently at {:.1f}/15)".format(breakdown.get("moocs_score", 0)))

        if any(term in msg_lower for term in ["cloud", "docker", "devops", "aws", "gcp"]):
            return (
                f"Hello {name}! Based on your digital twin, expanding into Cloud & DevOps will significantly elevate your market readiness for {target} roles.\n\n"
                f"### Recommended 3-Step Cloud Roadmap:\n"
                f"1. **Containerization Fundamentals**: Package one of your existing applications using **Docker** and write a `docker-compose.yml` configuration.\n"
                f"2. **Cloud Provider Essentials**: Complete the **AWS Certified Cloud Practitioner** or **Google Associate Cloud Engineer** learning track.\n"
                f"3. **CI/CD Automation**: Set up a GitHub Actions workflow that automatically tests and builds your project on every commit.\n\n"
                f"Adding a containerized project to your profile will directly boost your Technical Skills and Project readiness score!"
            )

        elif any(term in msg_lower for term in ["project", "portfolio", "build", "github"]):
            return (
                f"Great question, {name}! For a **{target}** profile, recruiters want to see end-to-end projects that demonstrate both core technical skills and missing gaps like **{gaps_str}**.\n\n"
                f"### High-Impact Project Ideas for You:\n"
                f"1. **Interactive Data/Analytics Pipeline**: Build an automated data scraper/API ingestion pipeline using Python and SQL, store data in PostgreSQL, and visualize KPIs on a dynamic dashboard.\n"
                f"2. **Production-Ready Web Service**: Create a full-stack dashboard integrating your core skills, containerize it, and deploy it to a live cloud host (Vercel, Render, or AWS).\n"
                f"3. **Domain Capstone**: Solve a campus or local business problem with real data, document the architecture clearly on GitHub, and include unit tests.\n\n"
                f"Recording this under your CareerTwin activities will elevate your **Projects pillar** by up to 7.5 points!"
            )

        elif any(term in msg_lower for term in ["readiness", "score", "improve", "boost", "category", "gap", "pillar"]):
            pillar_tips = "\n".join([f"- **{p}**" for p in low_pillars]) if low_pillars else "- Complete 1 additional industry certification this semester."
            return (
                f"Hi {name}! Your current Career Readiness Score is **{score}/100** ({category}).\n\n"
                f"### Key Growth Opportunities from your 7-Pillar Breakdown:\n"
                f"{pillar_tips}\n\n"
                f"### Top Missing Skill Gaps to Bridge:\n"
                f"- **{gaps_str}**: Completing a certified workshop or verified MOOC in these topics will close your profile gaps for **{target}** roles.\n\n"
                f"### Suggested Next Action:\n"
                f"Focus on submitting a verified Project or Hackathon certificate to jump from *{category}* into the *Job Ready* tier!"
            )

        else:
            return (
                f"Hello {name}! I am your **CareerTwin AI Career Coach**.\n\n"
                f"I've analyzed your academic digital twin: you're in **Year {ctx['current_year']} {ctx['department']}** maintaining a solid **{ctx['cgpa']} CGPA**, targeting a **{target}** career path.\n\n"
                f"### Quick Snapshot of Your Profile:\n"
                f"- **Career Readiness**: {score}/100 ({category})\n"
                f"- **Strengths**: {', '.join(list(ctx['skill_levels'].keys())[:3])}\n"
                f"- **Priority Skill Gaps**: {gaps_str}\n\n"
                f"How can I assist your career journey today? You can ask me about project ideas, interview prep, skill-building roadmaps, or how to boost your readiness score!"
            )

    def process_chat(self, student_id: str, message: str, chat_history: Optional[List[ChatMessage]] = None) -> ChatResponse:
        """Main chat pipeline combining context injection, Gemini LLM, and fallback mode."""
        history = chat_history or []
        ctx = self.get_student_context(student_id)
        system_prompt = self.build_system_prompt(ctx)

        gemini_reply = self.call_gemini(system_prompt, message, history)

        if gemini_reply:
            reply_text = gemini_reply.strip()
            source = "gemini"
        else:
            reply_text = self.generate_fallback_response(ctx, message)
            source = "rule_based_fallback"

        # Update chat history
        updated_history = list(history)
        updated_history.append(ChatMessage(role="user", content=message))
        updated_history.append(ChatMessage(role="model", content=reply_text))

        return ChatResponse(
            response=reply_text,
            chat_history=updated_history,
            student_id=student_id,
            source=source,
            student_context_summary={
                "name": ctx["name"],
                "target_role": ctx["target_role"],
                "cgpa": ctx["cgpa"],
                "readiness_score": ctx["career_readiness_score"],
                "readiness_category": ctx["readiness_category"],
                "missing_skills": ctx["missing_skills"]
            }
        )

chat_service = ChatService()
