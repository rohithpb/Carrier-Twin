import os
import sys
from pathlib import Path

# Add backend directory to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from services.model_service import model_service
from routers import students, mentors, recruiters, opportunities, recommendations, analytics, flashcards

app = FastAPI(
    title="CareerTwin AI Digital Twin & Guidance Platform API",
    description="FastAPI Backend for CareerTwin Educational Digital Twin, Skill Gap Analysis, Career Readiness Engine, Opportunity Matching, and Recruiter Discovery.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS Middleware
origins = [
    "http://localhost:3000",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
    "http://10.0.2.2:8000",
    "*"  # Allow all for development & mobile emulator access
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(students.router)
app.include_router(mentors.router)
app.include_router(recruiters.router)
app.include_router(opportunities.router)
app.include_router(recommendations.router)
app.include_router(analytics.router)
app.include_router(flashcards.router)

@app.get("/api/health", tags=["Health"])
def health_check():
    """Return backend operational status and ML model state."""
    return {
        "status": "healthy",
        "backend": "FastAPI",
        "ml_model": model_service.model_status_message
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
