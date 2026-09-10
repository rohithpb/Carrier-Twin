from datetime import datetime, timezone, timedelta
from typing import Dict, Any, Tuple

class SM2Service:
    """
    Spaced Repetition Scheduler inspired by SuperMemo-2 and Anki-Android.
    
    Ratings:
      1 = Again: Complete recall failure. Card lapses, repetitions reset to 0, EF - 0.20, interval = 1.
      2 = Hard: Remembered with high effort. EF - 0.15, interval grows conservatively (x 1.2).
      3 = Good: Normal successful recall. EF stays stable, interval = interval * EF.
      4 = Easy: Effortless recall. EF + 0.15, interval = interval * EF * 1.3 (Easy bonus).
    """

    MIN_EASE_FACTOR = 1.3
    DEFAULT_EASE_FACTOR = 2.5
    HARD_INTERVAL_FACTOR = 1.2
    EASY_BONUS = 1.3

    @classmethod
    def calculate(
        cls,
        rating: int,
        current_interval: int,
        current_ease_factor: float,
        current_repetitions: int
    ) -> Dict[str, Any]:
        """
        Calculate the next interval, ease factor, repetitions, and due date.
        """
        if rating < 1 or rating > 4:
            raise ValueError(f"Invalid Anki rating: {rating}. Must be between 1 (Again) and 4 (Easy).")

        interval = max(1, current_interval)
        ef = max(cls.MIN_EASE_FACTOR, current_ease_factor)
        reps = max(0, current_repetitions)

        old_ef = ef

        if rating == 1:
            # Again (Lapse)
            reps = 0
            interval = 1
            ef = max(cls.MIN_EASE_FACTOR, ef - 0.20)
        elif rating == 2:
            # Hard
            reps += 1
            ef = max(cls.MIN_EASE_FACTOR, ef - 0.15)
            if reps == 1:
                interval = 1
            elif reps == 2:
                interval = 3
            else:
                interval = max(interval + 1, round(interval * cls.HARD_INTERVAL_FACTOR))
        elif rating == 3:
            # Good
            if reps == 0:
                interval = 1
            elif reps == 1:
                interval = 6
            else:
                interval = max(interval + 1, round(interval * ef))
            reps += 1
        elif rating == 4:
            # Easy
            ef += 0.15
            if reps == 0:
                interval = 4
            elif reps == 1:
                interval = 8
            else:
                interval = max(interval + 2, round(interval * ef * cls.EASY_BONUS))
            reps += 1

        now = datetime.now(timezone.utc)
        due_date = now + timedelta(days=interval)

        return {
            "interval": int(interval),
            "easeFactor": round(float(ef), 2),
            "repetitions": int(reps),
            "dueDate": due_date.isoformat(),
            "easeFactorChange": round(float(ef - old_ef), 2),
        }

sm2_service = SM2Service()
