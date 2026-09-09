import os
from typing import Dict, Any, List, Optional
from google import genai
from google.genai import types

from services.firebase_service import db_service
from services.readiness_service import readiness_service
from schemas.chat import ChatMessage, ChatResponse

def generate_career_coach_response(student_profile: dict, user_message: str, chat_history: list = None) -> str:
    """
    Generates a personalized career coaching response using the Gemini API 
    by injecting the student's digital twin profile as context.
    """
    # Initialize the official Google GenAI client (picks up GEMINI_API_KEY from environment variables)
    client = genai.Client()

    # Extract digital twin metrics safely with fallbacks
    name = student_profile.get("name", "Student")
    cgpa = student_profile.get("cgpa", "N/A")
    department = student_profile.get("department", "General")
    skills = ", ".join(student_profile.get("skills", ["None listed"]))
    readiness_score = student_profile.get("readiness_score", 0)
    pillars = student_profile.get("pillars_breakdown", {})
    missing_gaps = ", ".join(student_profile.get("missing_gaps", ["None identified"]))

    # Construct the dynamic system prompt with context injection
    system_instruction = (
        f"You are CareerTwin Coach, an expert, empathetic, and highly analytical university career counselor. "
        f"You are advising {name}, a student in the {department} department with a CGPA of {cgpa}. "
        f"Their overall Career Readiness Score is {readiness_score}/100. "
        f"Their current technical skills include: {skills}. "
        f"Their identified skill gaps and missing requirements for target roles are: {missing_gaps}. "
        f"Pillar breakdown scores: {pillars}. "
        f"Guidelines: Always reference their specific data (CGPA, missing gaps, or skills) when answering. "
        f"Keep your tone encouraging, direct, and actionable. Provide concrete next steps (such as specific projects, "
        f"certifications, or internships) to help them bridge their exact gaps."
    )

    # Format historical chat contents for the Gemini API if provided
    contents = []
    if chat_history:
        for msg in chat_history:
            if isinstance(msg, dict):
                role = "user" if msg.get("sender") == "user" or msg.get("role") == "user" else "model"
                text = msg.get("text") or msg.get("content") or ""
            else:
                role = "model" if getattr(msg, "role", "") in ["model", "assistant"] else "user"
                text = getattr(msg, "content", "")

            if text:
                contents.append(types.Content(
                    role=role,
                    parts=[types.Part.from_text(text=text)]
                ))

    # Append the current user message
    contents.append(types.Content(
        role="user",
        parts=[types.Part.from_text(text=user_message)]
    ))

    # Call the Gemini model using the recommended gemini-2.5-flash model
    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    response = client.models.generate_content(
        model=model_name,
        contents=contents,
        config=types.GenerateContentConfig(
            system_instruction=system_instruction,
            temperature=0.7,
            max_output_tokens=800,
        ),
    )

    return response.text


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
            "missing_skills": missing_skills,
            # Profile keys matching generate_career_coach_response
            "readiness_score": readiness_score,
            "pillars_breakdown": score_breakdown,
            "missing_gaps": missing_skills
        }

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

        gemini_reply = None
        # Attempt Gemini invocation if GEMINI_API_KEY is configured
        if os.getenv("GEMINI_API_KEY", "").strip():
            try:
                gemini_reply = generate_career_coach_response(
                    student_profile=ctx,
                    user_message=message,
                    chat_history=history
                )
            except Exception as e:
                print(f"[ChatService] Gemini generation error: {e}. Switching to heuristic fallback.")

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
