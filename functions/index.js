const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * FEATURE 4 & 5: Predict GPA Impact and Workload / Burnout Risk
 * Uses pre-trained scikit-learn Linear Regression coefficients hardcoded into Cloud Function.
 */
exports.predictGpaImpact = functions.https.onCall((data, context) => {
  const currentGpa = parseFloat(data.currentGpa || 3.0);
  const weeklyStudyHours = parseFloat(data.weeklyStudyHours || 15);
  const certPrepHours = parseFloat(data.certPrepHours || 5);
  const stressLevel = parseFloat(data.stressLevel || 5); // 1-10 scale
  const activeSkillsCount = parseInt(data.activeSkillsCount || 3, 10);

  // Linear Regression Coefficients (trained offline on Kaggle Academic Performance dataset)
  // GPA_delta = beta0 + beta1*StudyHours + beta2*CertHours - beta3*StressLevel + beta4*Skills
  const beta0 = -0.05;
  const betaStudy = 0.018;
  const betaCert = 0.014;
  const betaStress = 0.032;
  const betaSkills = 0.010;

  const predictedDelta =
    beta0 +
    betaStudy * weeklyStudyHours +
    betaCert * certPrepHours -
    betaStress * stressLevel +
    betaSkills * activeSkillsCount;

  let predictedGpa = Math.min(4.0, Math.max(1.0, currentGpa + predictedDelta));
  predictedGpa = Math.round(predictedGpa * 100) / 100;

  // Workload Gauge Calculation (0-100 score)
  // Workload = (StudyHours * 1.2) + (CertHours * 1.6) + (StressLevel * 3.0)
  let workloadScore = (weeklyStudyHours * 1.2) + (certPrepHours * 1.6) + (stressLevel * 3.0);
  workloadScore = Math.min(100, Math.round(workloadScore));

  // Burnout Threshold Logic: Rule-based evaluation
  const isBurnoutRisk = (stressLevel >= 7 && workloadScore >= 65) || workloadScore >= 80;

  let burnoutWarningMessage = "";
  if (isBurnoutRisk) {
    if (stressLevel >= 8) {
      burnoutWarningMessage = "CRITICAL BURNOUT RISK: High stress levels detected. Reduce cert-prep by at least 4 hours this week.";
    } else {
      burnoutWarningMessage = "WARNING: Heavy workload detected. Consider pacing your skill modules to preserve GPA stability.";
    }
  }

  return {
    success: true,
    currentGpa: currentGpa,
    predictedGpa: predictedGpa,
    gpaDelta: Math.round(predictedDelta * 100) / 100,
    workloadScore: workloadScore,
    isBurnoutRisk: isBurnoutRisk,
    burnoutWarningMessage: burnoutWarningMessage,
    timestamp: new Date().toISOString()
  };
});

/**
 * FEATURE 6: Mentor Matching using Cosine Similarity
 * Vector fields: [Frontend, Backend, Cloud, ML, DevOps]
 */
exports.matchMentors = functions.https.onCall(async (data, context) => {
  const studentVector = data.skillVector || [3, 2, 1, 0, 1]; // Array of 5 skill proficiency scores (1-5)

  // Hardcoded mentor profiles (5-10 profiles)
  const dummyMentors = [
    {
      id: "m1",
      name: "Dr. Sarah Jenkins",
      role: "Senior Cloud Architect @ AWS",
      path: "Cloud Computing",
      vector: [2, 4, 5, 2, 5],
      avatarUrl: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150",
      skills: ["AWS", "Kubernetes", "Linux", "Terraform"],
      bio: "10+ years experience in distributed cloud infrastructure & DevOps pipelines."
    },
    {
      id: "m2",
      name: "Arjun Nair",
      role: "Staff Full Stack Engineer @ Vercel",
      path: "Full Stack Development",
      vector: [5, 5, 3, 1, 3],
      avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
      skills: ["React", "Node.js", "TypeScript", "GraphQL", "PostgreSQL"],
      bio: "Passionate about modern JS ecosystem, serverless apps, and web performance."
    },
    {
      id: "m3",
      name: "Priya Sharma",
      role: "Lead Machine Learning Researcher",
      path: "Machine Learning",
      vector: [1, 2, 2, 5, 2],
      avatarUrl: "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150",
      skills: ["PyTorch", "Python", "Scikit-Learn", "Computer Vision"],
      bio: "Specializing in deep learning models, Kaggle Master, and AI mentorship."
    },
    {
      id: "m4",
      name: "David Chen",
      role: "Senior Frontend Engineer",
      path: "Web Development",
      vector: [5, 2, 2, 0, 1],
      avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
      skills: ["HTML/CSS", "JavaScript", "Vue.js", "UI/UX Architecture"],
      bio: "Building slick responsive interfaces, accessibility champion."
    },
    {
      id: "m5",
      name: "Elena Rostova",
      role: "DevOps & Cloud Engineer",
      path: "Cloud Computing",
      vector: [1, 3, 5, 1, 5],
      avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
      skills: ["Docker", "CI/CD", "GCP", "Bash Automation"],
      bio: "Helping students transition from academic projects to production deployments."
    }
  ];

  // Helper cosine similarity formula
  const cosineSimilarity = (vecA, vecB) => {
    let dotProduct = 0;
    let normA = 0;
    let normB = 0;
    for (let i = 0; i < vecA.length; i++) {
      const a = vecA[i] || 0;
      const b = vecB[i] || 0;
      dotProduct += a * b;
      normA += a * a;
      normB += b * b;
    }
    if (normA === 0 || normB === 0) return 0;
    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
  };

  const matches = dummyMentors.map(mentor => {
    const sim = cosineSimilarity(studentVector, mentor.vector);
    return {
      ...mentor,
      matchPercentage: Math.round(sim * 100)
    };
  });

  // Sort descending by similarity match percentage
  matches.sort((a, b) => b.matchPercentage - a.matchPercentage);

  return {
    success: true,
    mentors: matches
  };
});
