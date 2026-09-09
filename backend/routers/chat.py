from fastapi import APIRouter, HTTPException, status
from schemas.chat import ChatRequest, ChatResponse
from services.chat_service import chat_service

router = APIRouter(prefix="/api/chat", tags=["Career Coach"])

@router.post("", response_model=ChatResponse, status_code=status.HTTP_200_OK)
def chat_with_career_coach(req: ChatRequest):
    """
    GenAI Conversational Career Coach Endpoint.
    Dynamically injects student digital twin context (CGPA, skill levels, 7-pillar readiness breakdown, and missing skills)
    into a personalized prompt for Google Gemini, with a resilient profile-aware fallback mechanism.
    """
    if not req.message or not req.message.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message cannot be empty."
        )

    try:
        return chat_service.process_chat(
            student_id=req.student_id,
            message=req.message.strip(),
            chat_history=req.chat_history or []
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred while generating career coach guidance: {str(e)}"
        )
