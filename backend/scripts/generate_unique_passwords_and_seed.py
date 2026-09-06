import json
import random
import string
import csv
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
PROJECT_ROOT = BASE_DIR.parent

def generate_secure_temp_password(prefix=""):
    chars = string.ascii_letters + string.digits
    rand_str = ''.join(random.choices(chars, k=6))
    symbols = ["!", "@", "#", "$", "%", "*"]
    sym = random.choice(symbols)
    return f"{prefix}{rand_str}{sym}"

def process_and_seed():
    print("Generating unique secure temporary passwords for all Students, Mentors, and Recruiters...")

    # 1. Update Students
    students_file = DATA_DIR / "demo_students.json"
    with open(students_file, "r", encoding="utf-8") as f:
        students = json.load(f)

    student_creds_rows = []
    all_creds_rows = [["Role", "ID / Username", "Name", "Email", "Unique Temporary Password", "Department / Company / College"]]

    for i, s in enumerate(students):
        admission_no = s.get("admission_no", s.get("username", f"23CS{101+i}"))
        college_code = "JECC" if "jecc" in s.get("email", "") else ("MACE" if "mace" in s.get("email", "") else "GECT")
        temp_pass = generate_secure_temp_password(prefix="S@")
        
        s["temp_password"] = temp_pass
        s["must_reset_password"] = True
        s["mustResetPassword"] = True

        student_creds_rows.append([college_code, admission_no, s["name"], s.get("email", ""), temp_pass])
        all_creds_rows.append(["Student", admission_no, s["name"], s.get("email", ""), temp_pass, f"{college_code} {s.get('department', '')}"])

    with open(students_file, "w", encoding="utf-8") as f:
        json.dump(students, f, indent=2)

    # 2. Update Mentors
    mentors_file = DATA_DIR / "demo_mentors.json"
    with open(mentors_file, "r", encoding="utf-8") as f:
        mentors = json.load(f)

    for m in mentors:
        username = m.get("username", m["id"])
        temp_pass = generate_secure_temp_password(prefix="M@")
        m["temp_password"] = temp_pass
        m["must_reset_password"] = True
        m["mustResetPassword"] = True

        all_creds_rows.append(["Faculty / Mentor", username, m["name"], m.get("email", ""), temp_pass, f"{m.get('department', '')} Dept"])

    with open(mentors_file, "w", encoding="utf-8") as f:
        json.dump(mentors, f, indent=2)

    # 3. Update Recruiters
    recruiters_file = DATA_DIR / "demo_recruiters.json"
    with open(recruiters_file, "r", encoding="utf-8") as f:
        recruiters = json.load(f)

    for r in recruiters:
        username = r.get("username", r["id"])
        temp_pass = generate_secure_temp_password(prefix="R@")
        r["temp_password"] = temp_pass
        r["must_reset_password"] = True
        r["mustResetPassword"] = True

        all_creds_rows.append(["Recruiter / T&P", username, r["name"], r.get("email", ""), temp_pass, r.get("company", "Company")])

    with open(recruiters_file, "w", encoding="utf-8") as f:
        json.dump(recruiters, f, indent=2)

    # Write all_credentials.csv
    all_creds_file = PROJECT_ROOT / "all_credentials.csv"
    with open(all_creds_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerows(all_creds_rows)
    print(f"Updated all_credentials.csv with {len(all_creds_rows)-1} user credentials.")

    # Write credentials_out.csv
    creds_out_file = PROJECT_ROOT / "credentials_out.csv"
    with open(creds_out_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["College", "Admission No", "Student Name", "Synthetic Email", "Temporary Password"])
        for row in student_creds_rows:
            writer.writerow(row)
    print("Updated credentials_out.csv with student credentials.")

    # Run seed_demo_data.py to sync into Firebase Firestore
    try:
        from seed_demo_data import seed_demo_data
        seed_demo_data()
    except Exception as e:
        print(f"Seed script error: {e}")

if __name__ == "__main__":
    process_and_seed()
