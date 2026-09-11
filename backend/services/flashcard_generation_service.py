import os
import json
import httpx
from typing import List, Dict, Any, Optional

class FlashcardGenerationService:
    """
    Topic-Specific Flashcard Generator using LLM (NVIDIA NIM / Gemini / OpenAI)
    with a rich fallback knowledge engine for university course modules.
    """

    CURRICULUM_BANK: Dict[str, List[Dict[str, str]]] = {
        "dbms": [
            {
                "front": "What are the key differences between 3NF and BCNF in relational databases?",
                "back": "3NF allows a non-prime attribute to be functionally dependent on another non-prime attribute if it is part of a candidate key. BCNF is stricter: every determinant X -> Y must have X as a superkey. BCNF eliminates all functional dependency anomalies.",
                "tag": "DBMS"
            },
            {
                "front": "Explain the ACID properties in database transaction management.",
                "back": "• Atomicity: All or nothing execution.\n• Consistency: Database remains in valid state before and after transaction.\n• Isolation: Concurrent transactions do not interfere with each other.\n• Durability: Once committed, updates persist even across system crashes.",
                "tag": "DBMS"
            },
            {
                "front": "Why are B+ Trees preferred over B Trees for disk-based relational database indexes?",
                "back": "1. All data pointers/records are stored in leaf nodes, leaving internal nodes with more fan-out keys.\n2. Leaf nodes are linked sequentially as a doubly-linked list, making range queries and scans O(log N + K) rather than requiring full tree traversals.",
                "tag": "DBMS"
            },
            {
                "front": "What is the difference between Clustered and Non-Clustered Indexes?",
                "back": "• Clustered: Physical storage order of table rows matches the index order. Only 1 clustered index per table.\n• Non-Clustered: Creates a separate index structure with pointers back to row addresses (or clustered key). Multiple non-clustered indexes can exist.",
                "tag": "DBMS"
            },
            {
                "front": "How does the Write-Ahead Logging (WAL) protocol prevent data loss during sudden crashes?",
                "back": "WAL enforces that any log record describing a database modification must be flushed to non-volatile disk before the corresponding page changes are written to the database file. On recovery, REDO and UNDO passes restore consistency.",
                "tag": "DBMS"
            }
        ],
        "python": [
            {
                "front": "What is the Python Global Interpreter Lock (GIL) and how does it affect multithreading?",
                "back": "The GIL is a mutex that allows only one native thread to execute Python bytecode at a time in CPython. While I/O-bound programs benefit from threading, CPU-bound tasks must use multiprocessing or C extensions to achieve true parallelism across CPU cores.",
                "tag": "Python"
            },
            {
                "front": "Explain how Python Generators and the 'yield' statement achieve memory efficiency.",
                "back": "Generators produce items lazily on-demand using the iterator protocol rather than instantiating the entire sequence in memory. When 'yield' is executed, the function's execution state, local variables, and instruction pointer are saved and paused.",
                "tag": "Python"
            },
            {
                "front": "What is the difference between '__init__' and '__new__' in Python classes?",
                "back": "• '__new__' is the actual constructor method called first to create and return a new instance of the class.\n• '__init__' is the initializer called after the instance has been created to customize its state.",
                "tag": "Python"
            },
            {
                "front": "How does Python handle memory management and cyclic reference garbage collection?",
                "back": "Python primarily uses reference counting for immediate deallocation when refcount reaches 0. To detect circular references (e.g. A references B and B references A), CPython runs a cyclic generational garbage collector (Generations 0, 1, 2) utilizing doubly-linked lists.",
                "tag": "Python"
            },
            {
                "front": "Explain the '@classmethod' vs '@staticmethod' decorators in Python.",
                "back": "• '@classmethod' receives the class object 'cls' as its first parameter and can modify class-wide state or act as alternate factory constructors.\n• '@staticmethod' receives neither 'self' nor 'cls'; it behaves like a plain function placed inside a class namespace for organizational cohesion.",
                "tag": "Python"
            }
        ],
        "operating systems": [
            {
                "front": "What are the four necessary conditions for a Deadlock (Coffman conditions)?",
                "back": "1. Mutual Exclusion: Resources cannot be shared simultaneously.\n2. Hold and Wait: Process holds resource while requesting another.\n3. No Preemption: Resources cannot be forcibly taken away.\n4. Circular Wait: A closed chain of processes each waiting for a resource held by the next.",
                "tag": "Operating Systems"
            },
            {
                "front": "Explain the difference between Paging and Segmentation in Virtual Memory.",
                "back": "• Paging: Divides memory into fixed-size physical frames and logical pages. Eliminates external fragmentation but may have internal fragmentation.\n• Segmentation: Divides memory into variable-sized logical segments (code, data, stack) reflecting programmer views. Eliminates internal fragmentation but can cause external fragmentation.",
                "tag": "Operating Systems"
            },
            {
                "front": "What is the Translation Lookaside Buffer (TLB) and how does it prevent memory lookup penalties?",
                "back": "The TLB is a fast hardware associative cache inside the MMU that stores recent virtual-to-physical page table translations. A TLB hit avoids an extra access to main memory, speeding up instruction execution from 2 memory cycles to 1.",
                "tag": "Operating Systems"
            },
            {
                "front": "Compare Mutex vs Counting Semaphore for thread synchronization.",
                "back": "• Mutex: Binary locking mechanism owned exclusively by the locking thread. Only the owner thread can unlock it.\n• Semaphore: Signaling mechanism that maintains an integer counter. Any thread can post/signal it. Allows up to N concurrent threads access.",
                "tag": "Operating Systems"
            }
        ],
        "computer networks": [
            {
                "front": "Explain the TCP 3-Way Handshake connection establishment process.",
                "back": "1. Client -> Server: SYN (seq = x)\n2. Server -> Client: SYN-ACK (seq = y, ack = x + 1)\n3. Client -> Server: ACK (ack = y + 1)\nEstablishes sequence numbers and synchronizes parameters before data flow.",
                "tag": "Computer Networks"
            },
            {
                "front": "What is the difference between TCP Flow Control and TCP Congestion Control?",
                "back": "• Flow Control: Prevents the sender from overwhelming the receiver's receive buffer (uses sliding window advertisement 'rwnd').\n• Congestion Control: Prevents the sender from overwhelming the network intermediate routers (uses congestion window 'cwnd', Slow Start, Congestion Avoidance, AIMD).",
                "tag": "Computer Networks"
            },
            {
                "front": "Explain the purpose of ARP (Address Resolution Protocol) and how it maps addresses.",
                "back": "ARP resolves a known Layer 3 IP address to a physical Layer 2 MAC address on the local network link. It broadcasts an ARP Request frame to all nodes (FF:FF:FF:FF:FF:FF), and the matching target node unicasts back its MAC address.",
                "tag": "Computer Networks"
            }
        ]
    }

    async def generate_cards(
        self,
        topic: str,
        notes: Optional[str] = None,
        count: int = 5
    ) -> List[Dict[str, str]]:
        """
        Generates Anki-style active recall cards for the given topic using LLM
        or intelligent curriculum mapping.
        """
        from dotenv import load_dotenv
        load_dotenv(override=False)

        openai_api_key = os.getenv("OPENAI_API_KEY", "").strip()
        gemini_api_key = os.getenv("GEMINI_API_KEY", "").strip()
        nvidia_api_key = os.getenv("NVIDIA_API_KEY", "").strip()
        if not openai_api_key and nvidia_api_key.startswith("sk-"):
            openai_api_key = nvidia_api_key

        # 1. Try OpenAI API if key is present
        if openai_api_key:
            try:
                cards = await self._generate_with_openai(openai_api_key, topic, notes, count)
                if cards:
                    return cards
            except Exception as e:
                print(f"OpenAI generation error: {e}")

        # 2. Try Gemini API if key is present (or failover from OpenAI)
        if gemini_api_key:
            try:
                cards = await self._generate_with_gemini(gemini_api_key, topic, notes, count)
                if cards:
                    return cards
            except Exception as e:
                print(f"Gemini generation error: {e}")

        groq_api_key = os.getenv("GROQ_API_KEY", "").strip()

        # 3. Try NVIDIA NIM API if key is present
        if nvidia_api_key and not nvidia_api_key.startswith("sk-"):
            try:
                cards = await self._generate_with_nvidia(nvidia_api_key, topic, notes, count)
                if cards:
                    return cards
            except Exception as e:
                print(f"NVIDIA NIM generation error: {e}")

        # 4. Try Groq API if key is present
        if groq_api_key:
            try:
                cards = await self._generate_with_groq(groq_api_key, topic, notes, count)
                if cards:
                    return cards
            except Exception as e:
                print(f"Groq generation error: {e}")

        # 5. Fallback Knowledge Engine
        return self._generate_from_curriculum(topic, notes, count)

    async def _generate_with_nvidia(
        self,
        api_key: str,
        topic: str,
        notes: Optional[str],
        count: int
    ) -> List[Dict[str, str]]:
        url = "https://integrate.api.nvidia.com/v1/chat/completions"
        system_prompt = (
            "You are an expert university professor creating high-retention Anki spaced repetition flashcards. "
            "Output ONLY a JSON list of objects with keys 'front', 'back', and 'tag'. "
            "'front' must be a concise, active-recall question testing a single concept. "
            "'back' must be a clear, precise explanation with bullet points. "
            "Do not include markdown fences outside the JSON."
        )
        user_prompt = f"Topic: {topic}\n"
        if notes:
            user_prompt += f"Course Materials/Notes:\n{notes[:1500]}\n"
        user_prompt += f"Generate exactly {count} flashcards as a JSON array."

        models = [
            "nvidia/nemotron-3.5-lightning-30b-a3b",
            "meta/llama-3.3-70b-instruct",
            "meta/llama-3.1-70b-instruct"
        ]
        async with httpx.AsyncClient(timeout=20.0) as client:
            for model in models:
                try:
                    res = await client.post(
                        url,
                        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                        json={
                            "model": model,
                            "messages": [
                                {"role": "system", "content": system_prompt},
                                {"role": "user", "content": user_prompt}
                            ],
                            "temperature": 0.4,
                            "max_tokens": 1500
                        }
                    )
                    if res.status_code == 200:
                        content = res.json()["choices"][0]["message"]["content"]
                        cards = self._parse_json_cards(content, topic)
                        if cards:
                            return cards
                except Exception as e:
                    print(f"NVIDIA NIM ({model}) flashcard error: {e}")
                    continue
        return []

    async def _generate_with_groq(
        self,
        api_key: str,
        topic: str,
        notes: Optional[str],
        count: int
    ) -> List[Dict[str, str]]:
        url = "https://api.groq.com/openai/v1/chat/completions"
        system_prompt = (
            "You are an expert university professor creating high-retention Anki spaced repetition flashcards. "
            "Output ONLY a JSON list of objects with keys 'front', 'back', and 'tag'. "
            "'front' must be a concise, active-recall question testing a single concept. "
            "'back' must be a clear, precise explanation with bullet points. "
            "Do not include markdown fences outside the JSON."
        )
        user_prompt = f"Topic: {topic}\n"
        if notes:
            user_prompt += f"Course Materials/Notes:\n{notes[:1500]}\n"
        user_prompt += f"Generate exactly {count} flashcards as a JSON array."

        models = ["llama-3.3-70b-versatile", "llama-3.1-8b-instant", "qwen/qwen3.6-27b"]
        async with httpx.AsyncClient(timeout=20.0) as client:
            for model in models:
                try:
                    res = await client.post(
                        url,
                        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                        json={
                            "model": model,
                            "messages": [
                                {"role": "system", "content": system_prompt},
                                {"role": "user", "content": user_prompt}
                            ],
                            "temperature": 0.4,
                            "max_tokens": 1500
                        }
                    )
                    if res.status_code == 200:
                        content = res.json()["choices"][0]["message"]["content"]
                        cards = self._parse_json_cards(content, topic)
                        if cards:
                            return cards
                except Exception as e:
                    print(f"Groq ({model}) flashcard error: {e}")
                    continue
        return []

    async def _generate_with_openai(
        self,
        api_key: str,
        topic: str,
        notes: Optional[str],
        count: int
    ) -> List[Dict[str, str]]:
        url = "https://api.openai.com/v1/chat/completions"
        system_prompt = (
            "You are an Anki flashcard creator. Generate high-yield active-recall question and answer pairs. "
            "Return JSON array with 'front', 'back', and 'tag'."
        )
        user_prompt = f"Topic: {topic}\nGenerate {count} flashcards as a JSON array."
        if notes:
            user_prompt += f"\nNotes:\n{notes[:1200]}"

        async with httpx.AsyncClient(timeout=15.0) as client:
            res = await client.post(
                url,
                headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                json={
                    "model": "gpt-4o-mini",
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt}
                    ],
                    "temperature": 0.3,
                    "response_format": {"type": "json_object"} if "json_object" in res.text else None
                }
            )
            if res.status_code == 200:
                content = res.json()["choices"][0]["message"]["content"]
                return self._parse_json_cards(content, topic)
        return []

    async def _generate_with_gemini(
        self,
        api_key: str,
        topic: str,
        notes: Optional[str],
        count: int
    ) -> List[Dict[str, str]]:
        prompt = (
            f"Generate exactly {count} Anki flashcards for the computer science topic: '{topic}'. "
            f"Optional notes: {notes or 'None'}. "
            "Format your response as a valid JSON array of objects with keys: 'front', 'back', 'tag'."
        )
        models = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash"]
        async with httpx.AsyncClient(timeout=20.0) as client:
            for model in models:
                try:
                    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
                    res = await client.post(
                        url,
                        headers={"Content-Type": "application/json"},
                        json={
                            "contents": [{"parts": [{"text": prompt}]}],
                            "generationConfig": {"temperature": 0.3}
                        }
                    )
                    if res.status_code == 200:
                        text = res.json()["candidates"][0]["content"]["parts"][0]["text"]
                        cards = self._parse_json_cards(text, topic)
                        if cards:
                            return cards
                except Exception as e:
                    print(f"Gemini ({model}) flashcard error: {e}")
                    continue
        return []

    def _parse_json_cards(self, text: str, default_tag: str) -> List[Dict[str, str]]:
        """Cleans and extracts JSON array from LLM responses."""
        cleaned = text.strip()
        if cleaned.startswith("```json"):
            cleaned = cleaned[7:]
        if cleaned.startswith("```"):
            cleaned = cleaned[3:]
        if cleaned.endswith("```"):
            cleaned = cleaned[:-3]
        cleaned = cleaned.strip()

        try:
            data = json.loads(cleaned)
            if isinstance(data, dict):
                # If wrapped in a key like {"flashcards": [...]}
                for key in ["flashcards", "cards", "data", "items"]:
                    if key in data and isinstance(data[key], list):
                        data = data[key]
                        break
            if isinstance(data, list):
                results = []
                for item in data:
                    if isinstance(item, dict) and "front" in item and "back" in item:
                        results.append({
                            "front": str(item["front"]),
                            "back": str(item["back"]),
                            "tag": str(item.get("tag", default_tag))
                        })
                return results
        except Exception as e:
            print(f"JSON parsing error: {e} on text: {cleaned[:100]}")
        return []

    def _generate_from_curriculum(
        self,
        topic: str,
        notes: Optional[str],
        count: int
    ) -> List[Dict[str, str]]:
        """Intelligent fallback selection and card synthesis based on topic matching."""
        topic_lower = topic.lower()

        # Check domain matches
        matched_category = None
        for key in self.CURRICULUM_BANK.keys():
            if key in topic_lower or any(word in topic_lower for word in key.split()):
                matched_category = key
                break

        if not matched_category:
            # Check default mapping
            if any(w in topic_lower for w in ["database", "sql", "query", "acid", "index", "normalization"]):
                matched_category = "dbms"
            elif any(w in topic_lower for w in ["code", "script", "function", "gil", "generator", "async"]):
                matched_category = "python"
            elif any(w in topic_lower for w in ["memory", "process", "thread", "deadlock", "paging", "mutex"]):
                matched_category = "operating systems"
            elif any(w in topic_lower for w in ["network", "tcp", "ip", "packet", "socket", "http", "routing"]):
                matched_category = "computer networks"
            else:
                matched_category = "dbms"

        pool = self.CURRICULUM_BANK.get(matched_category, self.CURRICULUM_BANK["dbms"])
        cards = []
        for card in pool[:count]:
            cards.append({
                "front": card["front"],
                "back": card["back"],
                "tag": topic if len(topic) <= 24 else card["tag"]
            })

        # If user supplied custom notes, synthesize a dedicated note card
        if notes and len(notes.strip()) > 30:
            notes_clean = notes.strip()
            first_sentence = notes_clean.split(".")[0]
            cards.insert(0, {
                "front": f"Explain the core principle behind: '{topic}' from your course notes.",
                "back": f"Key note summary:\n• {first_sentence}.\n\nContextual Detail:\n{notes_clean[:220]}...",
                "tag": topic[:20]
            })

        return cards[:count]

flashcard_generator = FlashcardGenerationService()
