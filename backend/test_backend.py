import json
from main import app
from fastapi.testclient import TestClient

client = TestClient(app)

def test_all():
    print("Testing /api/health...")
    res = client.get("/api/health")
    assert res.status_code == 200, res.text
    print("Health:", res.json())

    print("\nTesting /api/students...")
    res = client.get("/api/students")
    assert res.status_code == 200
    students = res.json()
    print(f"Fetched {len(students)} students.")
    first_id = students[0]["id"]

    print(f"\nTesting /api/students/{first_id}/digital-twin...")
    res = client.get(f"/api/students/{first_id}/digital-twin")
    assert res.status_code == 200
    print("Digital Twin:", json.dumps(res.json(), indent=2)[:300] + "...")

    print(f"\nTesting /api/students/{first_id}/readiness...")
    res = client.get(f"/api/students/{first_id}/readiness")
    assert res.status_code == 200
    print("Readiness:", res.json())

    print(f"\nTesting /api/predict-career for {first_id}...")
    res = client.post("/api/predict-career", json={"student_id": first_id})
    assert res.status_code == 200
    print("Predictions:", res.json())

    print("\nTesting /api/mentors/mentor001/analytics...")
    res = client.get("/api/mentors/mentor001/analytics")
    assert res.status_code == 200
    print("Mentor Analytics:", res.json())

    print("\nTesting /api/recruiters/recruiter001/match-students...")
    res = client.post("/api/recruiters/recruiter001/match-students", json={
        "job_role": "Data Analyst",
        "required_skills": ["Python", "SQL", "Power BI"],
        "min_match_score": 60
    })
    assert res.status_code == 200
    candidates = res.json()["candidates"]
    print(f"Matched {len(candidates)} candidates.")

    print("\nTesting /api/placement/analytics...")
    res = client.get("/api/placement/analytics")
    assert res.status_code == 200
    print("Placement Analytics:", res.json())

    print("\nALL BACKEND API TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    test_all()
