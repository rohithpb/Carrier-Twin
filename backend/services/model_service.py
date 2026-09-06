import os
import joblib
import pickle
from pathlib import Path
from typing import Dict, Any, List, Tuple

BASE_DIR = Path(__file__).resolve().parent.parent
DEFAULT_MODEL_PATH = BASE_DIR / "models" / "career_model.pkl"

class ModelService:
    def __init__(self):
        self.model = None
        self.scaler = None
        self.label_encoder = None
        self.ml_mode = False
        self.model_status_message = "Not loaded (using Rule-based Fallback Engine)"
        self.load_model()

    def load_model(self):
        model_path_str = os.getenv("MODEL_PATH", str(DEFAULT_MODEL_PATH))
        model_path = Path(model_path_str) if not os.path.isabs(model_path_str) else Path(model_path_str)

        if not model_path.exists():
            print(f"ML Model file not found at '{model_path}'. Running in Rule-Based Fallback Mode.")
            self.ml_mode = False
            self.model_status_message = "Rule-based Engine (career_model.pkl missing)"
            return

        try:
            # Attempt loading model using joblib or pickle
            try:
                self.model = joblib.load(model_path)
            except Exception:
                with open(model_path, "rb") as f:
                    self.model = pickle.load(f)

            self.ml_mode = True
            self.model_status_message = "loaded"
            print(f"Successfully loaded ML model from '{model_path}'. ML_MODE enabled.")

            # Optionally load scaler and label encoder if present
            scaler_path = model_path.parent / "scaler.pkl"
            if scaler_path.exists():
                self.scaler = joblib.load(scaler_path)

            le_path = model_path.parent / "label_encoder.pkl"
            if le_path.exists():
                self.label_encoder = joblib.load(le_path)

        except Exception as e:
            print(f"Error loading ML model from '{model_path}': {e}. Falling back to Rule-Based Mode.")
            self.ml_mode = False
            self.model_status_message = f"Rule-based Engine (Load Error: {str(e)})"

    def predict_career(self, student_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Runs ML prediction if pickle model is loaded, otherwise uses rule-based prediction.
        """
        if self.ml_mode and self.model is not None:
            try:
                # Prepare features array if model expects tabular vector
                # E.g. [cgpa, python_score, sql_score, aws_score, react_score, ...]
                skills = student_data.get("skill_levels", {})
                cgpa = student_data.get("cgpa", 7.5)
                features = [
                    cgpa,
                    skills.get("Python", 0),
                    skills.get("SQL", 0),
                    skills.get("AWS", 0),
                    skills.get("React", 0),
                    skills.get("Java", 0),
                    skills.get("Linux", 0),
                    skills.get("Power BI", 0),
                    skills.get("Flutter", 0),
                    skills.get("Docker", 0),
                ]
                
                if self.scaler:
                    features = self.scaler.transform([features])
                else:
                    features = [features]

                # Model predict or predict_proba
                if hasattr(self.model, "predict_proba"):
                    probs = self.model.predict_proba(features)[0]
                    classes = self.model.classes_ if hasattr(self.model, "classes_") else range(len(probs))
                    
                    if self.label_encoder:
                        classes = self.label_encoder.inverse_transform(classes)

                    results = []
                    for role, prob in zip(classes, probs):
                        results.append({"role": str(role), "confidence": int(round(prob * 100))})
                    
                    results.sort(key=lambda x: x["confidence"], reverse=True)
                    return results[:3]
                else:
                    pred = self.model.predict(features)[0]
                    if self.label_encoder:
                        pred = self.label_encoder.inverse_transform([pred])[0]
                    return [{"role": str(pred), "confidence": 85}]

            except Exception as e:
                print(f"Error during ML inference: {e}. Falling back to Rule-Based prediction.")

        # Rule-Based Prediction Fallback
        return self._rule_based_prediction(student_data)

    def _rule_based_prediction(self, student_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        target_role = student_data.get("target_role", "Software Engineer")
        skills = student_data.get("skill_levels", {})
        
        # Calculate suitability scores for popular career roles
        role_scores = {
            "Data Analyst": skills.get("Python", 0) * 0.4 + skills.get("SQL", 0) * 0.4 + skills.get("Power BI", 0) * 0.2,
            "Full Stack Developer": skills.get("React", 0) * 0.35 + skills.get("JavaScript", 0) * 0.35 + skills.get("Node.js", 0) * 0.3,
            "Cloud Engineer": skills.get("AWS", 0) * 0.4 + skills.get("Linux", 0) * 0.35 + skills.get("Docker", 0) * 0.25,
            "Machine Learning Engineer": skills.get("Python", 0) * 0.4 + skills.get("TensorFlow", 0) * 0.3 + skills.get("PyTorch", 0) * 0.3,
            "Cybersecurity Analyst": skills.get("Networking", 0) * 0.4 + skills.get("Linux", 0) * 0.3 + skills.get("Wireshark", 0) * 0.3,
            "Backend Developer": skills.get("Java", 0) * 0.4 + skills.get("SQL", 0) * 0.3 + skills.get("Python", 0) * 0.3,
            "Mobile App Developer": skills.get("Flutter", 0) * 0.5 + skills.get("Dart", 0) * 0.3 + skills.get("Firebase", 0) * 0.2,
            "DevOps Engineer": skills.get("Docker", 0) * 0.4 + skills.get("Linux", 0) * 0.35 + skills.get("AWS", 0) * 0.25,
        }

        # Boost target role
        if target_role in role_scores:
            role_scores[target_role] += 15

        sorted_roles = sorted(role_scores.items(), key=lambda item: item[1], reverse=True)

        results = []
        for role, score in sorted_roles[:3]:
            conf = min(95, max(50, int(score)))
            results.append({"role": role, "confidence": conf})

        return results

model_service = ModelService()
