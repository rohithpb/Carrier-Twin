import os
import joblib
import numpy as np
import pandas as pd
from pathlib import Path
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler, LabelEncoder

# Path Setup
BASE_DIR = Path(__file__).resolve().parent.parent
MODELS_DIR = BASE_DIR / "models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)

MODEL_PATH = MODELS_DIR / "career_model.pkl"
SCALER_PATH = MODELS_DIR / "scaler.pkl"
ENCODER_PATH = MODELS_DIR / "label_encoder.pkl"

def generate_training_data(n_samples=500):
    """
    Generates synthetic training dataset based on realistic student skill profiles and target career roles.
    Features: [cgpa, python, sql, aws, react, java, linux, power_bi]
    """
    np.random.seed(42)
    
    roles = [
        "Data Analyst",
        "Full Stack Developer",
        "Cloud Engineer",
        "Machine Learning Engineer",
        "Cybersecurity Analyst",
        "Backend Developer",
        "Mobile App Developer",
        "DevOps Engineer"
    ]
    
    data = []
    labels = []
    
    for _ in range(n_samples):
        target_role = np.random.choice(roles)
        cgpa = round(np.random.uniform(6.0, 9.8), 2)
        
        # Base skill levels (0 to 100)
        python_score = np.random.randint(10, 60)
        sql_score = np.random.randint(10, 60)
        aws_score = np.random.randint(10, 60)
        react_score = np.random.randint(10, 60)
        java_score = np.random.randint(10, 60)
        linux_score = np.random.randint(10, 60)
        power_bi_score = np.random.randint(10, 60)
        flutter_score = np.random.randint(10, 60)
        docker_score = np.random.randint(10, 60)

        # High correlations based on role
        if target_role == "Data Analyst":
            python_score = np.random.randint(65, 98)
            sql_score = np.random.randint(70, 99)
            power_bi_score = np.random.randint(60, 95)
        elif target_role == "Full Stack Developer":
            react_score = np.random.randint(70, 99)
            python_score = np.random.randint(50, 90)
            sql_score = np.random.randint(50, 85)
        elif target_role == "Cloud Engineer":
            aws_score = np.random.randint(70, 99)
            linux_score = np.random.randint(65, 98)
            docker_score = np.random.randint(60, 90)
        elif target_role == "Machine Learning Engineer":
            python_score = np.random.randint(80, 100)
            sql_score = np.random.randint(60, 90)
        elif target_role == "Cybersecurity Analyst":
            linux_score = np.random.randint(75, 99)
            aws_score = np.random.randint(50, 85)
        elif target_role == "Backend Developer":
            java_score = np.random.randint(70, 99)
            sql_score = np.random.randint(65, 95)
        elif target_role == "Mobile App Developer":
            flutter_score = np.random.randint(75, 100)
            python_score = np.random.randint(40, 80)
        elif target_role == "DevOps Engineer":
            docker_score = np.random.randint(75, 100)
            linux_score = np.random.randint(70, 98)
            aws_score = np.random.randint(65, 95)

        features = [cgpa, python_score, sql_score, aws_score, react_score, java_score, linux_score, power_bi_score, flutter_score, docker_score]
        data.append(features)
        labels.append(target_role)

    return np.array(data), np.array(labels)

def train_and_save():
    print("Generating training dataset...")
    X, y = generate_training_data(n_samples=1000)

    print("Encoding labels and scaling features...")
    label_encoder = LabelEncoder()
    y_encoded = label_encoder.fit_transform(y)

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    print("Training RandomForestClassifier model...")
    model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
    model.fit(X_scaled, y_encoded)

    print(f"Saving model artifacts to {MODELS_DIR}...")
    joblib.dump(model, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)
    joblib.dump(label_encoder, ENCODER_PATH)

    print("Model training complete! Saved:")
    print(f" - Main Model: {MODEL_PATH}")
    print(f" - Scaler: {SCALER_PATH}")
    print(f" - Label Encoder: {ENCODER_PATH}")

if __name__ == "__main__":
    train_and_save()
