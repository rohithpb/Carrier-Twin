import os
import json
import httpx
from typing import Dict, Any, Optional, List
from pathlib import Path
from dotenv import load_dotenv
from openai import OpenAI
from services.firebase_service import db_service

# =====================================================================
# 🔑 API KEYS CONFIGURATION (Supports OpenAI & Google Gemini)
# =====================================================================
OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")


class AcademicAdvisorService:
    """
    Academic & Career Advisor Service powered by OpenAI (GPT-4o / GPT-4o-mini)
    and Google Gemini with automatic dual-engine failover & Student Digital Twin context.
    """

    def __init__(self):
        self._openai_models = [
            "gpt-4o-mini",
            "gpt-4o",
            "gpt-3.5-turbo",
        ]
        self._gemini_models = [
            "gemini-2.5-flash",
            "gemini-flash-latest",
            "gemini-2.0-flash",
            "gemini-1.5-flash",
        ]

    def _reload_env(self):
        """Reload .env dynamically to capture keys saved without server restart."""
        env_path = Path(__file__).resolve().parent.parent / ".env"
        load_dotenv(dotenv_path=env_path, override=True)

    def get_openai_key(self) -> str:
        self._reload_env()
        key = os.getenv("OPENAI_API_KEY", "").strip() or OPENAI_API_KEY.strip()
        if not key:
            # Fallback if user pasted sk- key in NVIDIA_API_KEY
            alt = os.getenv("NVIDIA_API_KEY", "").strip()
            if alt.startswith("sk-") or alt.startswith("xpl_"):
                key = alt
        return key

    def get_openai_base_url(self) -> Optional[str]:
        self._reload_env()
        base_url = os.getenv("OPENAI_API_BASE", "").strip()
        if not base_url and self.get_openai_key().startswith("xpl_"):
            base_url = "https://api.experientiallabs.ai/v1"
        return base_url if base_url else None

    def get_groq_key(self) -> str:
        self._reload_env()
        return os.getenv("GROQ_API_KEY", "").strip()

    def get_gemini_key(self) -> str:
        self._reload_env()
        return os.getenv("GEMINI_API_KEY", "").strip() or GEMINI_API_KEY.strip()

    def get_nvidia_key(self) -> str:
        self._reload_env()
        return os.getenv("NVIDIA_API_KEY", "").strip()

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
            student = db_service.get_student_by_id("student001") or {}

        name = student.get("name") or student.get("student") or "Student"
        dept = department or student.get("department") or "Computer Science"
        curr_year = student.get("current_year", 2)
        sem = semester or (curr_year * 2)
        cgpa = student.get("cgpa", 8.0)
        role = target_role or student.get("target_role") or "Software Engineer"
        industry = student.get("target_industry") or "Technology"

        skills_data = student.get("skills", [])
        if isinstance(skills_data, dict):
            skills_str = ", ".join([f"{k} ({v}%)" for k, v in skills_data.items()])
        elif isinstance(skills_data, list):
            skills_str = ", ".join([str(s) for s in skills_data])
        else:
            skills_str = "Python, SQL, DSA, Web Development"

        skill_gaps = student.get("missing_skills") or student.get("skill_gap") or []
        gaps_str = ", ".join(skill_gaps) if skill_gaps else "None identified"

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

    async def _call_openai(self, prompt: str, system_context: str, api_key: str) -> Dict[str, Any]:
        """Calls OpenAI or Experiential Labs Gateway with model fallback."""
        base_url = self.get_openai_base_url()
        if base_url:
            client = OpenAI(
                api_key=api_key,
                base_url=base_url
            )
            models = ["gpt-4o-mini", "gpt-4o", "gpt-3.5-turbo", "deepseek-v4-flash", "qwen3.8-27b"]
            provider_label = "Experiential Labs (OpenAI)" if "experientiallabs" in base_url else "OpenAI Gateway"
        else:
            client = OpenAI(api_key=api_key)
            models = self._openai_models
            provider_label = "OpenAI"

        last_error = None
        for model in models:
            try:
                completion = client.chat.completions.create(
                    model=model,
                    messages=[
                        {"role": "system", "content": system_context},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.3,
                    top_p=0.8,
                    max_tokens=1500,
                    stream=False
                )
                reply = completion.choices[0].message.content
                if reply and reply.strip():
                    return {
                        "reply": reply.strip(),
                        "model": model,
                        "provider": f"{provider_label} ({model})",
                    }
            except Exception as e:
                last_error = str(e)
                print(f"{provider_label} ({model}) error: {e}")
                if "insufficient_quota" in last_error or "card_required" in last_error or "429" in last_error:
                    break
                continue

        raise Exception(last_error or f"{provider_label} call failed on all models.")

    async def _call_groq(self, prompt: str, system_context: str, api_key: str) -> Dict[str, Any]:
        """Calls Groq or xAI Grok API with automatic provider detection and model fallback."""
        if api_key.startswith("xai-"):
            client = OpenAI(api_key=api_key, base_url="https://api.x.ai/v1")
            models = ["grok-2-latest", "grok-2", "grok-beta"]
            provider_label = "xAI Grok"
        else:
            client = OpenAI(api_key=api_key, base_url="https://api.groq.com/openai/v1")
            models = [
                "llama-3.3-70b-versatile",
                "llama-3.1-8b-instant",
                "qwen/qwen3.6-27b",
                "groq/compound",
                "groq/compound-mini"
            ]
            provider_label = "Groq"

        last_error = None
        for model in models:
            try:
                completion = client.chat.completions.create(
                    model=model,
                    messages=[
                        {"role": "system", "content": system_context},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.3,
                    max_tokens=1500,
                )
                reply = completion.choices[0].message.content
                if reply and reply.strip():
                    return {
                        "reply": reply.strip(),
                        "model": model,
                        "provider": f"{provider_label} ({model})",
                    }
            except Exception as e:
                last_error = str(e)
                print(f"{provider_label} ({model}) error: {e}")
                if "invalid_api_key" in str(e).lower() or "401" in str(e):
                    break
                continue

        raise Exception(last_error or f"{provider_label} call failed on all models.")

    async def _call_gemini(self, prompt: str, system_context: str, api_key: str) -> Dict[str, Any]:
        """Calls Google Gemini REST API with multi-model fallback."""
        last_error = None
        full_prompt = f"{system_context}\n\nUser Question:\n{prompt}"

        async with httpx.AsyncClient(timeout=35.0) as client:
            for model in self._gemini_models:
                try:
                    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
                    payload = {
                        "contents": [
                            {
                                "role": "user",
                                "parts": [{"text": full_prompt}]
                            }
                        ],
                        "generationConfig": {
                            "temperature": 0.3,
                            "maxOutputTokens": 2048
                        }
                    }
                    res = await client.post(url, json=payload, headers={"Content-Type": "application/json"})
                    if res.status_code == 200:
                        data = res.json()
                        candidates = data.get("candidates", [])
                        if candidates:
                            parts = candidates[0].get("content", {}).get("parts", [])
                            if parts and "text" in parts[0]:
                                return {
                                    "reply": parts[0]["text"].strip(),
                                    "model": model,
                                    "provider": f"Google Gemini ({model})",
                                }
                    else:
                        last_error = f"Gemini ({model}) HTTP {res.status_code}: {res.text[:200]}"
                except Exception as e:
                    last_error = f"Gemini ({model}) error: {e}"
                    continue

        raise Exception(last_error or "Google Gemini call failed on all models.")

    async def _call_nvidia(self, prompt: str, system_context: str, api_key: str) -> Dict[str, Any]:
        """
        Calls NVIDIA NIM via OpenAI-compatible SDK (https://integrate.api.nvidia.com/v1)
        Powered by nvidia/nemotron-3.5-lightning-30b-a3b with ultra-fast conversational response.
        """
        client = OpenAI(
            base_url="https://integrate.api.nvidia.com/v1",
            api_key=api_key
        )
        models = [
            "nvidia/nemotron-3.5-lightning-30b-a3b",
            "meta/llama-3.3-70b-instruct",
            "meta/llama-3.1-8b-instruct"
        ]
        last_error = None
        for model in models:
            try:
                completion = client.chat.completions.create(
                    model=model,
                    messages=[
                        {"role": "system", "content": system_context},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.6,
                    top_p=0.95,
                    max_tokens=1500,
                    extra_body={"chat_template_kwargs": {"enable_thinking": False}},
                    stream=False
                )
                reply = completion.choices[0].message.content
                if reply and reply.strip():
                    return {
                        "reply": reply.strip(),
                        "model": model,
                        "provider": f"NVIDIA NIM ({model})",
                    }
            except Exception as e:
                last_error = str(e)
                print(f"NVIDIA NIM ({model}) error: {e}")
                continue

        raise Exception(last_error or "NVIDIA NIM call failed on all models.")

    async def generate_response(
        self,
        question: str,
        student_id: str = "student001",
        department: Optional[str] = None,
        semester: Optional[int] = None,
        target_role: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Executes AI response generation powered primarily by NVIDIA NIM (Nemotron 30B)
        with automatic Google Gemini fallback.
        """
        system_context = self._build_digital_twin_context(
            student_id=student_id,
            department=department,
            semester=semester,
            target_role=target_role,
        )

        nvidia_key = self.get_nvidia_key()
        gemini_key = self.get_gemini_key()

        # If neither key is configured yet, provide curriculum answer
        if not nvidia_key and not gemini_key:
            return {
                "reply": self._smart_academic_fallback(question, department, semester),
                "model": "offline-fallback",
                "has_api_key": False,
                "provider": "Offline Curriculum Fallback",
            }

        errors = []

        # 1. Primary Engine: NVIDIA NIM (nvidia/nemotron-3.5-lightning-30b-a3b)
        if nvidia_key and nvidia_key.startswith("nvapi-"):
            try:
                res = await self._call_nvidia(question, system_context, nvidia_key)
                return {
                    "reply": res["reply"],
                    "model": res["model"],
                    "has_api_key": True,
                    "provider": res["provider"],
                }
            except Exception as e:
                errors.append(f"NVIDIA NIM: {e}")
                print(f"[WARN] NVIDIA NIM failed ({e}). Proceeding to Gemini failover...")

        # 2. Secondary Engine: Google Gemini (Rock solid multi-model fallback)
        if gemini_key:
            try:
                res = await self._call_gemini(question, system_context, gemini_key)
                return {
                    "reply": res["reply"],
                    "model": res["model"],
                    "has_api_key": True,
                    "provider": f"Google Gemini ({res['model']})",
                }
            except Exception as e:
                errors.append(f"Gemini: {e}")
                print(f"[WARN] Gemini call failed: {e}")

        # If both failed:
        return {
            "reply": (
                f"⚠️ **AI Generation Error**:\n\n"
                + "\n".join([f"• `{err}`" for err in errors])
                + "\n\nPlease verify your `NVIDIA_API_KEY` and `GEMINI_API_KEY` in `backend/.env`."
            ),
            "model": "error",
            "has_api_key": True,
            "error": " | ".join(errors),
            "provider": "Error State",
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
                "*💡 To enable live OpenAI GPT-4o or Gemini generation, paste your keys in `backend/.env`.*"
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
                "*💡 To enable live OpenAI GPT-4o or Gemini generation, paste your keys in `backend/.env`.*"
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
                "*💡 To enable live OpenAI GPT-4o or Gemini generation, paste your keys in `backend/.env`.*"
            )

        return (
            f"Hello! I am your CareerTwin Academic AI Advisor.\n\n"
            f"You asked: \"{question}\"\n\n"
            "To generate live, real-time answers powered by **OpenAI (GPT-4o)** or **Google Gemini**:\n\n"
            "👉 **Paste your API keys in `backend/.env`:**\n"
            "• `OPENAI_API_KEY=sk-...`\n"
            "• `GEMINI_API_KEY=AQ.Ab8...`\n\n"
            "Once saved, CareerTwin automatically connects to the AI models and uses your digital twin profile to answer your questions!"
        )


academic_advisor_service = AcademicAdvisorService()
