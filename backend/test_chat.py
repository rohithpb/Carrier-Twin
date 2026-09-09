import json
from main import app
from fastapi.testclient import TestClient

client = TestClient(app)

def test_career_coach_chat():
    print("--- Testing Career Coach Endpoint /api/chat ---")
    
    # 1. Basic query with student001
    payload = {
        "student_id": "student001",
        "message": "How can I improve my Cloud and DevOps skills?"
    }
    res = client.post("/api/chat", json=payload)
    assert res.status_code == 200, f"Expected 200, got {res.status_code}: {res.text}"
    data = res.json()
    
    assert "response" in data
    assert "chat_history" in data
    assert len(data["chat_history"]) == 2
    assert data["student_id"] == "student001"
    assert data["source"] in ["gemini", "rule_based_fallback"]
    assert data["student_context_summary"] is not None
    assert data["student_context_summary"]["name"] == "Arjun Nair"
    assert data["student_context_summary"]["target_role"] == "Data Analyst"
    print("[PASS] Basic chat passed with context injection. Source:", data["source"])
    print("Coach reply sample:", data["response"][:120] + "...")

    # 2. Multi-turn chat history
    history = data["chat_history"]
    payload2 = {
        "student_id": "student001",
        "message": "What projects should I build next to raise my readiness score?",
        "chat_history": history
    }
    res2 = client.post("/api/chat", json=payload2)
    assert res2.status_code == 200, res2.text
    data2 = res2.json()
    assert len(data2["chat_history"]) == 4
    print("[PASS] Multi-turn history preserved. History length:", len(data2["chat_history"]))

    # 3. Empty message validation
    res3 = client.post("/api/chat", json={"student_id": "student001", "message": "   "})
    assert res3.status_code == 400
    print("[PASS] Empty message correctly returned 400 Bad Request.")

    print("\nALL CAREER COACH CHAT API TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    test_career_coach_chat()
