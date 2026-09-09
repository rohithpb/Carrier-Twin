from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any

class ChatMessage(BaseModel):
    role: str = Field(description="Role of the sender: 'user', 'model', or 'assistant'")
    content: str = Field(description="Message text")

class ChatRequest(BaseModel):
    student_id: str = Field(default="student001", description="ID of the student to fetch digital twin context")
    message: str = Field(..., description="The student's message/query for the career coach")
    chat_history: Optional[List[ChatMessage]] = Field(default=[], description="Previous turns of conversation")

class ChatResponse(BaseModel):
    response: str = Field(description="Career coach's response")
    chat_history: List[ChatMessage] = Field(description="Updated conversation history with newest message pair")
    student_id: str = Field(description="ID of the student")
    source: str = Field(description="'gemini' or 'rule_based_fallback'")
    student_context_summary: Optional[Dict[str, Any]] = Field(default=None, description="Summary of student digital twin metrics used")
