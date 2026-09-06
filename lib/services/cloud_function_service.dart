import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/simulation.dart';
import '../models/mentor.dart';

class CloudFunctionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Feature 4 & 5: Predict GPA Impact & Workload / Burnout Risk
  Future<SimulationResult> predictGpaImpact({
    required double currentGpa,
    required double weeklyStudyHours,
    required double certPrepHours,
    required int stressLevel,
    required int activeSkillsCount,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('predictGpaImpact');
      final response = await callable.call({
        'currentGpa': currentGpa,
        'weeklyStudyHours': weeklyStudyHours,
        'certPrepHours': certPrepHours,
        'stressLevel': stressLevel,
        'activeSkillsCount': activeSkillsCount,
      });

      if (response.data != null) {
        return SimulationResult.fromMap(Map<String, dynamic>.from(response.data));
      }
    } catch (e) {
      // Fallback calculation matching the Linear Regression Cloud Function equation
      // when offline or before Firebase is configured.
      return _calculateOfflineSimulation(
        currentGpa: currentGpa,
        weeklyStudyHours: weeklyStudyHours,
        certPrepHours: certPrepHours,
        stressLevel: stressLevel,
        activeSkillsCount: activeSkillsCount,
      );
    }

    return _calculateOfflineSimulation(
      currentGpa: currentGpa,
      weeklyStudyHours: weeklyStudyHours,
      certPrepHours: certPrepHours,
      stressLevel: stressLevel,
      activeSkillsCount: activeSkillsCount,
    );
  }

  /// Feature 6: Cosine Similarity Mentor Match
  Future<List<Mentor>> matchMentors({
    required List<int> skillVector,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('matchMentors');
      final response = await callable.call({
        'skillVector': skillVector,
      });

      if (response.data != null && response.data['mentors'] != null) {
        final List rawList = response.data['mentors'];
        return rawList.map((m) => Mentor.fromMap(Map<String, dynamic>.from(m))).toList();
      }
    } catch (e) {
      // Offline fallback cosine similarity calculation
      return _calculateOfflineMentorMatch(skillVector);
    }
    return _calculateOfflineMentorMatch(skillVector);
  }

  /// Offline engine logic for demo standalone running
  SimulationResult _calculateOfflineSimulation({
    required double currentGpa,
    required double weeklyStudyHours,
    required double certPrepHours,
    required int stressLevel,
    required int activeSkillsCount,
  }) {
    const beta0 = -0.05;
    const betaStudy = 0.018;
    const betaCert = 0.014;
    const betaStress = 0.032;
    const betaSkills = 0.010;

    final double delta = beta0 +
        (betaStudy * weeklyStudyHours) +
        (betaCert * certPrepHours) -
        (betaStress * stressLevel) +
        (betaSkills * activeSkillsCount);

    final double rawGpa = (currentGpa + delta).clamp(1.0, 4.0);
    final double predictedGpa = (rawGpa * 100).round() / 100;
    final double gpaDelta = (delta * 100).round() / 100;

    int workloadScore = ((weeklyStudyHours * 1.2) + (certPrepHours * 1.6) + (stressLevel * 3.0)).round();
    workloadScore = workloadScore.clamp(0, 100);

    final bool isBurnoutRisk = (stressLevel >= 7 && workloadScore >= 65) || workloadScore >= 80;

    String warningMessage = "";
    if (isBurnoutRisk) {
      if (stressLevel >= 8) {
        warningMessage = "CRITICAL BURNOUT RISK: High stress levels detected. Reduce cert-prep by at least 4 hours this week.";
      } else {
        warningMessage = "WARNING: Heavy workload detected. Consider pacing your skill modules to preserve GPA stability.";
      }
    }

    return SimulationResult(
      currentGpa: currentGpa,
      predictedGpa: predictedGpa,
      gpaDelta: gpaDelta,
      workloadScore: workloadScore,
      isBurnoutRisk: isBurnoutRisk,
      burnoutWarningMessage: warningMessage,
    );
  }

  List<Mentor> _calculateOfflineMentorMatch(List<int> studentVector) {
    final List<Map<String, dynamic>> dummyMentors = [
      {
        "id": "m1",
        "name": "Dr. Sarah Jenkins",
        "role": "Senior Cloud Architect @ AWS",
        "path": "Cloud Computing",
        "vector": [2, 4, 5, 2, 5],
        "avatarUrl": "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150",
        "skills": ["AWS", "Kubernetes", "Linux", "Terraform"],
        "bio": "10+ years experience in distributed cloud infrastructure & DevOps pipelines."
      },
      {
        "id": "m2",
        "name": "Arjun Nair",
        "role": "Staff Full Stack Engineer @ Vercel",
        "path": "Full Stack Development",
        "vector": [5, 5, 3, 1, 3],
        "avatarUrl": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
        "skills": ["React", "Node.js", "TypeScript", "GraphQL", "PostgreSQL"],
        "bio": "Passionate about modern JS ecosystem, serverless apps, and web performance."
      },
      {
        "id": "m3",
        "name": "Priya Sharma",
        "role": "Lead Machine Learning Researcher",
        "path": "Machine Learning",
        "vector": [1, 2, 2, 5, 2],
        "avatarUrl": "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150",
        "skills": ["PyTorch", "Python", "Scikit-Learn", "Computer Vision"],
        "bio": "Specializing in deep learning models, Kaggle Master, and AI mentorship."
      },
      {
        "id": "m4",
        "name": "David Chen",
        "role": "Senior Frontend Engineer",
        "path": "Web Development",
        "vector": [5, 2, 2, 0, 1],
        "avatarUrl": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
        "skills": ["HTML/CSS", "JavaScript", "Vue.js", "UI/UX Architecture"],
        "bio": "Building slick responsive interfaces, accessibility champion."
      },
      {
        "id": "m5",
        "name": "Elena Rostova",
        "role": "DevOps & Cloud Engineer",
        "path": "Cloud Computing",
        "vector": [1, 3, 5, 1, 5],
        "avatarUrl": "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
        "skills": ["Docker", "CI/CD", "GCP", "Bash Automation"],
        "bio": "Helping students transition from academic projects to production deployments."
      }
    ];

    double cosineSim(List<int> a, List<int> b) {
      double dot = 0, normA = 0, normB = 0;
      for (int i = 0; i < a.length; i++) {
        final valA = a[i].toDouble();
        final valB = b[i].toDouble();
        dot += valA * valB;
        normA += valA * valA;
        normB += valB * valB;
      }
      if (normA == 0 || normB == 0) return 0.0;
      return dot / (sqrt(normA) * sqrt(normB));
    }

    final list = dummyMentors.map((m) {
      final vec = List<int>.from(m['vector']);
      final sim = cosineSim(studentVector, vec);
      final Map<String, dynamic> copy = Map.from(m);
      copy['matchPercentage'] = (sim * 100).round();
      return Mentor.fromMap(copy);
    }).toList();

    list.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    return list;
  }
}
