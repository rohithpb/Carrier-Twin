from typing import List, Dict, Any, Optional
from services.firebase_service import db_service

class OpportunityService:
    @staticmethod
    def get_all_opportunities(type_filter: Optional[str] = None) -> List[Dict[str, Any]]:
        opps = db_service.get_all_opportunities()
        if type_filter:
            opps = [o for o in opps if o.get("type", "").upper() == type_filter.upper()]
        return opps

    @staticmethod
    def get_opportunity_by_id(opp_id: str) -> Optional[Dict[str, Any]]:
        opps = db_service.get_all_opportunities()
        for o in opps:
            if o.get("id") == opp_id:
                return o
        return None

opportunity_service = OpportunityService()
