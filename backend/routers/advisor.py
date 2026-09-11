from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from services.academic_advisor_service import academic_advisor_service

router = APIRouter(tags=["Academic Advisor & Chatbot"])

class AdvisorChatRequest(BaseModel):
    message: str = Field(..., description="The student's question or query.")
    student_id: Optional[str] = Field("student001", description="Student ID to load Firestore Digital Twin context.")
    department: Optional[str] = Field(None, description="Optional department override.")
    semester: Optional[int] = Field(None, description="Optional semester override.")
    target_role: Optional[str] = Field(None, description="Optional target career role override.")

class AdvisorChatResponse(BaseModel):
    reply: str
    model: str = "nvidia/nemotron-3.5-lightning-30b-a3b"
    provider: str = "NVIDIA NIM"
    has_api_key: bool = False
    student_id: Optional[str] = None

@router.post("/api/advisor/chat", response_model=AdvisorChatResponse)
@router.post("/api/chat", response_model=AdvisorChatResponse)
async def chat_with_advisor(request: AdvisorChatRequest):
    """
    OpenAI & Gemini Chatbot endpoint.
    Injects student Firestore Digital Twin profile data and returns contextual
    academic and career guidance.
    """
    if not request.message or not request.message.strip():
        raise HTTPException(status_code=400, detail="Query message cannot be empty.")

    result = await academic_advisor_service.generate_response(
        question=request.message.strip(),
        student_id=request.student_id or "student001",
        department=request.department,
        semester=request.semester,
        target_role=request.target_role,
    )

    return AdvisorChatResponse(
        reply=result["reply"],
        model=result.get("model", "gpt-4o-mini"),
        provider=result.get("provider", "OpenAI"),
        has_api_key=result.get("has_api_key", False),
        student_id=request.student_id or "student001",
    )
