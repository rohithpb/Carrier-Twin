from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any, Optional
from services.opportunity_service import opportunity_service

router = APIRouter(prefix="/api/opportunities", tags=["Opportunities"])

@router.get("", response_model=List[Dict[str, Any]])
def get_opportunities(type: Optional[str] = Query(None, description="Filter by type: INTERNSHIP, WORKSHOP, MOOC, HACKATHON, CERTIFICATION, TRAINING, JOB")):
    """Return all available demo opportunities."""
    return opportunity_service.get_all_opportunities(type_filter=type)

@router.get("/{opp_id}", response_model=Dict[str, Any])
def get_opportunity_by_id(opp_id: str):
    """Return details of a specific opportunity."""
    opp = opportunity_service.get_opportunity_by_id(opp_id)
    if not opp:
        raise HTTPException(status_code=404, detail=f"Opportunity with ID '{opp_id}' not found.")
    return opp
