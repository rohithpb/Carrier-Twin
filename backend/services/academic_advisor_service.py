import os
import json
from typing import Dict, Any, Optional, List
from openai import OpenAI
from services.firebase_service import db_service

# =====================================================================
# 🔑 PASTE YOUR NVIDIA NIM API KEY HERE
# =====================================================================
# You can paste your NVIDIA NIM API key directly inside the quotes below:
# Example: NVIDIA_API_KEY = "nvapi-..."
# Or alternatively set it in the backend/.env file: NVIDIA_API_KEY=...
# =====================================================================

NVIDIA_API_KEY: str = os.getenv("NVIDIA_API_KEY", "")

# =====================================================================


class AcademicAdvisorService:
    """
    Academic & Career Advisor Service powered by NVIDIA NIM Llama 3.3.
    Integrates the OpenAI client configured for NVIDIA NIM with
    Student Digital Twin context injection.
    """

    def __init__(self):
        self._base_url = "https://integrate.api.nvidia.com/v1"
        self._model = "meta/llama-3.3-70b-instruct"

    def get_api_key(self) -> str:
        """Fetch API key from code constant or environment."""
        return NVIDIA_API_KEY.strip() or os.getenv("NVIDIA_API_KEY", "").strip()

    def get_client(self) -> Optional[OpenAI]:
        """Initializes the OpenAI client pointing to NVIDIA NIM endpoint."""
        api_key = self.get_api_key()
        if not api_key:
            return None
        return OpenAI(
            base_url=self._base_url,
            api_key=api_key,
        )

    def _build_digital_twin_context(
        self,
        student_id: str,
        department: Optional[str] = None,
        semester: Optional[int] = None,
        target_role: Optional[str] = None,
    ) -> str:
        """
        Retrieves the student's Firestore Digital Twin profile data and
        formats it into a structured context prompt for the LLM.
        """
        student = db_service.get_student_by_id(student_id)
        if not student:
            # Fallback to student001 if provided ID is demo/generic
            student = db_service.get_student_by_id("student001") or {}

        name = student.get("name") or student.get("student") or "Student"
        dept = department or student.get("department") or "Computer Science"
        curr_year = student.get("current_year", 2)
        sem = semester or (curr_year * 2)
        cgpa = student.get("cgpa", 8.0)
        role = target_role or student.get("target_role") or "Software Engineer"
        industry = student.get("target_industry") or "Technology"

        # Skills & proficiencies
        skills_data = student.get("skills", [])
        if isinstance(skills_data, dict):
            skills_str = ", ".join([f"{k} ({v}%)" for k, v in skills_data.items()])
        elif isinstance(skills_data, list):
            skills_str = ", ".join([str(s) for s in skills_data])
        else:
            skills_str = "Python, SQL, DSA, Web Development"

        # Skill gaps
        skill_gaps = student.get("missing_skills") or student.get("skill_gap") or []
        gaps_str = ", ".join(skill_gaps) if skill_gaps else "None identified"

        # Recent activities / milestones
        activities = student.get("activities", [])
        if activities:
            recent_acts = [
                f"• {a.get('title', 'Activity')} ({a.get('type', 'General')})"
                for a in activities[:4]
            ]
            acts_str = "\n".join(recent_acts)
        else:
            acts_str = "• Actively preparing for university semester exams & placement drives"

        return f"""You are CareerTwin, an empathetic and highly knowledgeable University Academic & Career AI Advisor.
You specialize in university engineering academics ({dept}, Semester {sem}), syllabus concepts, algorithm walkthroughs, semester exam preparation, and career guidance.

=== STUDENT DIGITAL TWIN PROFILE (From Firestore / Campus Records) ===
• Student Name: {name} (ID: {student_id})
• Department: {dept} | Semester: {sem} (Year {curr_year})
• Current CGPA: {cgpa}
• Target Career Role: {role} (Industry: {industry})
• Verified Technical Skills: {skills_str}
• Current Skill Gaps: {gaps_str}
• Recent Milestones & Activities:
{acts_str}
======================================================================

ADVISOR INSTRUCTIONS:
1. Academic In-Depth Answers: Answer academic, programming, or conceptual questions with thorough, step-by-step clarity. Include clean, syntax-highlighted code snippets, formulas, or ASCII diagrams where relevant.
2. University & Exam Context: Point out common university end-semester questions, viva focus areas, or key definitions to memorize.
3. Career Alignment: When discussing topics or projects, relate them to the student's target role ("{role}").
4. Tone & Style: Direct, encouraging, structured with bullet points and bold text for readability on mobile/web screens."""

    async def generate_response(
        self,
        question: str,
        student_id: str = "student001",
        department: Optional[str] = None,
        semester: Optional[int] = None,
        target_role: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Executes NVIDIA NIM Llama 3.3 chat completion with digital twin context injection.
        """
        client = self.get_client()
        system_context = self._build_digital_twin_context(
            student_id=student_id,
            department=department,
            semester=semester,
            target_role=target_role,
        )

        # If no API key is configured yet, provide clear instruction and curriculum answer
        if not client:
            return {
                "reply": self._smart_academic_fallback(question, department, semester),
                "model": self._model,
                "has_api_key": False,
                "provider": "NVIDIA NIM (Offline Fallback)",
            }

        try:
            completion = client.chat.completions.create(
                model=self._model,
                messages=[
                    {"role": "system", "content": system_context},
                    {"role": "user", "content": question}
                ],
                temperature=0.2,
                top_p=0.7,
                max_tokens=1024,
                stream=False
            )

            reply_content = completion.choices[0].message.content
            return {
                "reply": reply_content.strip(),
                "model": self._model,
                "has_api_key": True,
                "provider": "NVIDIA NIM (meta/llama-3.3-70b-instruct)",
            }
        except Exception as e:
            err_str = str(e)
            return {
                "reply": (
                    f"⚠️ **NVIDIA NIM Llama 3.3 Error**: {err_str}\n\n"
                    f"Please verify your `NVIDIA_API_KEY` in `backend/.env` or at line 15 in `backend/services/academic_advisor_service.py`."
                ),
                "model": self._model,
                "has_api_key": True,
                "error": err_str,
                "provider": "NVIDIA NIM",
            }

    def _smart_academic_fallback(self, question: str, department: Optional[str], semester: Optional[int]) -> str:
        """High-yield curriculum fallback when API key is awaiting configuration."""
        q = question.lower()
        if "normalization" in q or "dbms" in q or "1nf" in q or "bcnf" in q:
            return (
                "### 📚 Database Normalization (1NF to BCNF)\n\n"
                "Normalization organizes relational database tables to reduce redundancy and eliminate insertion, update, and deletion anomalies.\n\n"
                "• **1NF (First Normal Form)**: Attributes must be atomic (indivisible). No multi-valued attributes or repeating groups.\n"
                "• **2NF (Second Normal Form)**: Must be in 1NF AND have no partial dependency (every non-prime attribute depends fully on candidate keys).\n"
                "• **3NF (Third Normal Form)**: Must be in 2NF AND have no transitive dependency ($X \\rightarrow Y \\rightarrow Z$). Non-prime attributes must only depend on candidate keys.\n"
                "• **BCNF (Boyce-Codd Normal Form)**: For every functional dependency $X \\rightarrow Y$, $X$ must be a superkey.\n\n"
                "*Exam Tip: Show a sample Student(StudentID, CourseID, Instructor, Office) table with functional dependencies to earn full marks.*\n\n"
                "---\n"
                "*💡 To enable live NVIDIA Llama 3.3 generation, paste your `NVIDIA_API_KEY` in `backend/.env` or at line 15 in `backend/services/academic_advisor_service.py`.*"
            )
        elif "dijkstra" in q or "algorithm" in q or "graph" in q or "python" in q:
            return (
                "### 💻 Dijkstra's Shortest Path Algorithm (Python)\n\n"
                "Dijkstra's Algorithm finds the shortest path from a single source vertex to all other vertices in a directed/undirected graph with non-negative edge weights.\n\n"
                "```python\n"
                "import heapq\n\n"
                "def dijkstra(graph, start):\n"
                "    distances = {node: float('inf') for node in graph}\n"
                "    distances[start] = 0\n"
                "    pq = [(0, start)]  # (distance, node)\n\n"
                "    while pq:\n"
                "        curr_dist, u = heapq.heappop(pq)\n"
                "        if curr_dist > distances[u]:\n"
                "            continue\n"
                "        for v, weight in graph[u].items():\n"
                "            distance = curr_dist + weight\n"
                "            if distance < distances[v]:\n"
                "                distances[v] = distance\n"
                "                heapq.heappush(pq, (distance, v))\n"
                "    return distances\n"
                "```\n\n"
                "• **Time Complexity**: $O((V + E) \\log V)$ using min-heap priority queue.\n"
                "• **Limitation**: Fails with negative edge cycles (use Bellman-Ford instead).\n\n"
                "---\n"
                "*💡 To enable live NVIDIA Llama 3.3 generation, paste your `NVIDIA_API_KEY` in `backend/.env` or at line 15 in `backend/services/academic_advisor_service.py`.*"
            )
        elif "tcp" in q or "udp" in q or "handshake" in q or "network" in q:
            return (
                "### ⚙️ TCP 3-Way Handshake Protocol\n\n"
                "The Transmission Control Protocol (TCP) uses a three-way handshake to establish a reliable, sequenced connection:\n\n"
                "1. **SYN**: Client sends `SYN=1, Seq=X` (requesting synchronization).\n"
                "2. **SYN-ACK**: Server acknowledges client's sequence and sends its own: `SYN=1, ACK=1, Seq=Y, Ack=X+1`.\n"
                "3. **ACK**: Client confirms server's sequence: `ACK=1, Ack=Y+1, Seq=X+1`.\n\n"
                "Once completed, socket connection is established in ESTABLISHED state for full-duplex byte stream transmission.\n\n"
                "---\n"
                "*💡 To enable live NVIDIA Llama 3.3 generation, paste your `NVIDIA_API_KEY` in `backend/.env` or at line 15 in `backend/services/academic_advisor_service.py`.*"
            )

        return (
            f"Hello! I am your CareerTwin Academic AI Advisor.\n\n"
            f"You asked: \"{question}\"\n\n"
            "To generate live, real-time answers powered by **NVIDIA NIM Llama 3.3 (70B Instruct)**:\n\n"
            "👉 **Paste your `NVIDIA_API_KEY` in:**\n"
            "• `backend/services/academic_advisor_service.py` (Line 15: `NVIDIA_API_KEY = \"nvapi-...\"`)\n"
            "• OR in `backend/.env` as: `NVIDIA_API_KEY=nvapi-...`\n\n"
            "Once saved, the backend automatically connects to NVIDIA NIM and uses your digital twin profile to answer your questions!"
        )


academic_advisor_service = AcademicAdvisorService()
