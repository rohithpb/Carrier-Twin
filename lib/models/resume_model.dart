class ResumeData {
  String fullName;
  String email;
  String phone;
  String location;
  String githubUrl;
  String linkedinUrl;
  String summary;
  String collegeName;
  String degree;
  String department;
  String batch;
  double cgpa;
  String targetRole;
  List<String> coreSkills;
  List<String> frameworksAndTools;
  List<String> databasesAndCloud;
  List<ResumeProject> projects;
  List<ResumeCertification> certifications;

  ResumeData({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    required this.githubUrl,
    required this.linkedinUrl,
    required this.summary,
    required this.collegeName,
    required this.degree,
    required this.department,
    required this.batch,
    required this.cgpa,
    required this.targetRole,
    required this.coreSkills,
    required this.frameworksAndTools,
    required this.databasesAndCloud,
    required this.projects,
    required this.certifications,
  });

  int get atsScore {
    int score = 50;
    if (fullName.isNotEmpty && email.isNotEmpty) score += 10;
    if (summary.length > 30) score += 10;
    if (coreSkills.length >= 4) score += 10;
    if (projects.isNotEmpty) score += 10;
    if (certifications.isNotEmpty) score += 10;
    return score.clamp(0, 100);
  }
}

class ResumeProject {
  String title;
  String description;
  String techStack;

  ResumeProject({
    required this.title,
    required this.description,
    required this.techStack,
  });
}

class ResumeCertification {
  String title;
  String issuer;
  String year;

  ResumeCertification({
    required this.title,
    required this.issuer,
    required this.year,
  });
}
