import json
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_PATH = BASE_DIR / "data" / "demo_students.json"

def enrich_students():
    with open(DATA_PATH, "r", encoding="utf-8") as f:
        students = json.load(f)

    dept_prefixes = {
        "Computer Science": "CS",
        "Information Technology": "IT",
        "BCA": "BCA",
        "Electronics": "ECE"
    }

    for i, s in enumerate(students, 1):
        dept = s.get("department", "Computer Science")
        prefix = dept_prefixes.get(dept, "CS")
        year = s.get("current_year", 2)
        admission_yr = 25 - year # e.g. 23 for year 2

        adm_no = f"{admission_yr}{prefix}{i:03d}"
        
        s["username"] = adm_no
        s["admission_no"] = adm_no
        s["temp_password"] = "TempStudent123!"
        s["must_reset_password"] = True
        s["role"] = "student"

        # Replace non-Indian name Rhea Alexander if present
        if "Alexander" in s.get("name", ""):
            s["name"] = s["name"].replace("Alexander", "Ananth")
            s["email"] = "rhea.ananth@mace.ac.in"

    with open(DATA_PATH, "w", encoding="utf-8") as f:
        json.dump(students, f, indent=2)

    print(f"Successfully enriched {len(students)} student profiles with usernames, temp passwords, and roles.")

if __name__ == "__main__":
    enrich_students()
