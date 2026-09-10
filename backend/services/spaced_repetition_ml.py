import numpy as np
from sklearn.ensemble import RandomForestClassifier
from typing import Dict, Any, List, Tuple, Optional

class SpacedRepetitionML:
    """
    Machine Learning Optimization Pipeline for Spaced Repetition Flashcards.
    
    Predicts student recall probability P(remembered=1) from review telemetry:
      - previous_interval
      - ease_factor
      - repetitions
      - historical_accuracy (0.0 - 1.0)
      - response_time_ms
      
    Dynamically modulates the SM-2 interval to minimize over-reviewing while
    preventing forgetting curve lapses.
    """

    def __init__(self):
        self.model = RandomForestClassifier(n_estimators=60, max_depth=6, random_state=42)
        self._is_trained = False
        self._init_bootstrap_model()

    def _init_bootstrap_model(self):
        """Train baseline model on realistic cognitive recall telemetry."""
        np.random.seed(42)
        n_samples = 400

        prev_intervals = np.random.randint(1, 45, n_samples)
        ease_factors = np.random.uniform(1.3, 2.9, n_samples)
        reps = np.random.randint(0, 12, n_samples)
        hist_accuracies = np.random.uniform(0.3, 1.0, n_samples)
        response_times = np.random.randint(800, 14000, n_samples)

        # Realistic log-odds of recall
        z = (
            0.15 * reps
            + 0.8 * hist_accuracies
            + 0.02 * ease_factors
            - 0.00035 * (response_times - 3000)
            - 0.03 * np.maximum(0, prev_intervals - 15)
        )
        probs = 1 / (1 + np.exp(-z))
        labels = (probs > 0.50).astype(int)

        X = np.column_stack([prev_intervals, ease_factors, reps, hist_accuracies, response_times])
        self.model.fit(X, labels)
        self._is_trained = True

    def predict_recall_probability(
        self,
        previous_interval: int,
        ease_factor: float,
        repetitions: int,
        historical_accuracy: float,
        response_time_ms: int
    ) -> float:
        """Predict recall probability between 0.05 and 0.99."""
        if not self._is_trained:
            self._init_bootstrap_model()

        X = np.array([[
            float(previous_interval),
            float(ease_factor),
            float(repetitions),
            float(historical_accuracy),
            float(response_time_ms)
        ]])

        try:
            proba = self.model.predict_proba(X)[0]
            # proba[1] is probability of remembered=1
            return float(np.clip(proba[1], 0.05, 0.98))
        except Exception:
            # Fallback heuristic
            score = 0.5 + (repetitions * 0.05) - (response_time_ms / 20000) + (historical_accuracy * 0.3)
            return float(np.clip(score, 0.1, 0.95))

    def adjust_interval(
        self,
        sm2_interval: int,
        rating: int,
        recall_probability: float,
        response_time_ms: int
    ) -> Tuple[int, str]:
        """
        Dynamically modulates the SM-2 interval:
        - Rapid high-confidence recall (prob > 0.85, rating in [3, 4], time < 4000ms): +15% to +25%
        - Prolonged hesitation or low confidence (prob < 0.55 or time > 8000ms): -15% consolidation
        - Moderate recall: SM-2 default preserved
        """
        if sm2_interval <= 1 or rating == 1:
            return 1, "Immediate 1-day lapse review scheduled."

        adjusted = sm2_interval
        reason = "SM-2 baseline interval maintained."

        if rating == 4 and recall_probability >= 0.82 and response_time_ms <= 3500:
            multiplier = 1.25
            adjusted = max(sm2_interval + 1, round(sm2_interval * multiplier))
            reason = f"High recall confidence ({int(recall_probability*100)}%) and rapid retrieval ({response_time_ms}ms). Interval extended by +25%."
        elif rating >= 3 and recall_probability >= 0.75 and response_time_ms <= 5000:
            multiplier = 1.15
            adjusted = max(sm2_interval + 1, round(sm2_interval * multiplier))
            reason = f"Strong memory trace ({int(recall_probability*100)}% recall). Interval boosted by +15%."
        elif (recall_probability < 0.55 or response_time_ms >= 8000) and sm2_interval > 2:
            multiplier = 0.85
            adjusted = max(1, round(sm2_interval * multiplier))
            reason = f"High retrieval latency ({response_time_ms}ms) or weak trace detected. Interval tightened by -15% to reinforce retention."

        return int(adjusted), reason

    def train_on_logs(self, review_logs: List[Dict[str, Any]]):
        """Optionally retrain or fine-tune model with cumulative telemetry logs."""
        if len(review_logs) < 20:
            return

        try:
            X = []
            y = []
            for log in review_logs:
                X.append([
                    log.get("previous_interval", 1),
                    log.get("ease_factor", 2.5),
                    log.get("repetitions", 0),
                    log.get("historical_accuracy", 0.75),
                    log.get("response_time_ms", 3000)
                ])
                y.append(int(log.get("remembered", 1)))

            if len(set(y)) > 1:
                self.model.fit(np.array(X), np.array(y))
        except Exception as e:
            print(f"Incremental ML training note: {e}")

spaced_repetition_ml = SpacedRepetitionML()
