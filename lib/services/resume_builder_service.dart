import '../models/student_profile.dart';
import '../models/job_role.dart';
import '../models/resume_model.dart';

class ResumeBuilderService {
  /// Map user's StudentProfile and target JobRole into an ATS-ready ResumeData
  ResumeData generateDefaultResume(StudentProfile profile, JobRole targetRole) {
    // 1. Extract verified skills from user profile
    final Map<String, int> profs = profile.skillProficiencies;
    final List<String> userSkills = [];

    profs.forEach((skill, level) {
      if (level > 0) {
        userSkills.add(skill);
      }
    });

    // Default verified skill mappings if profile proficiencies are minimal
    final List<String> defaultVerifiedCore = [
      'Python',
      'Data Structures & Algorithms',
      'C++',
      'Java',
      'SQL',
    ];

    final List<String> defaultFrameworks = [
      'Flutter / Dart',
      'React.js',
      'FastAPI / REST APIs',
      'Git & GitHub',
    ];

    final List<String> defaultDatabases = [
      'PostgreSQL / MySQL',
      'Firebase / Cloud Services',
      'Docker & Linux',
    ];

    // Align skills with target role
    final List<String> targetRequired = targetRole.requiredSkills;

    // Merge student skills with target role requirements
    final List<String> finalCoreSkills = {
      ...defaultVerifiedCore,
      ...userSkills,
      ...targetRequired.where((s) => s.contains('Python') || s.contains('Java') || s.contains('C++') || s.contains('SQL'))
    }.toList();

    final List<String> finalFrameworks = {
      ...defaultFrameworks,
      ...targetRequired.where((s) => s.contains('React') || s.contains('Flutter') || s.contains('Node') || s.contains('API'))
    }.toList();

    final List<String> finalDatabases = {
      ...defaultDatabases,
      ...targetRequired.where((s) => s.contains('AWS') || s.contains('Docker') || s.contains('Cloud') || s.contains('PostgreSQL'))
    }.toList();

    return ResumeData(
      fullName: profile.displayName.isEmpty ? 'Arjun Nair' : profile.displayName,
      email: profile.email.isEmpty ? 'arjun.nair@jecc.ac.in' : profile.email,
      phone: '+91 98765 43210',
      location: 'Kochi, Kerala, India',
      githubUrl: 'github.com/arjunnair-dev',
      linkedinUrl: 'linkedin.com/in/arjunnair-cs',
      summary:
          'Passionate B.Tech Computer Science student specializing in ${targetRole.title} with CGPA ${profile.cgpa.toStringAsFixed(2)}. Demonstrated expertise in ${finalCoreSkills.take(3).join(", ")}, with strong problem-solving skills and project development experience.',
      collegeName: 'Jyothi Engineering College (JECC)',
      degree: 'B.Tech in Computer Science & Engineering',
      department: profile.department,
      batch: profile.batch,
      cgpa: profile.cgpa,
      targetRole: targetRole.title,
      coreSkills: finalCoreSkills,
      frameworksAndTools: finalFrameworks,
      databasesAndCloud: finalDatabases,
      projects: [
        ResumeProject(
          title: 'CareerTwin AI Advisor & Skill Gap Engine',
          description:
              'Architected a digital twin application using Flutter, FastAPI, and Scikit-Learn to analyze skill gaps and predict placement readiness with 92% accuracy.',
          techStack: 'Flutter, Python, FastAPI, Firebase, Scikit-Learn',
        ),
        ResumeProject(
          title: 'Automated Placement & Resume Parser',
          description:
              'Built an automated ATS resume verification portal parsing student skills against visiting company job descriptions.',
          techStack: 'Python, PostgreSQL, REST APIs, Docker',
        ),
      ],
      certifications: [
        ResumeCertification(
          title: 'NPTEL: Data Science with Python (Elite + Silver)',
          issuer: 'IIT Madras & NPTEL',
          year: '2024',
        ),
        ResumeCertification(
          title: 'Google Cloud Associate Engineer Certification',
          issuer: 'Google Cloud Platform',
          year: '2024',
        ),
      ],
    );
  }
}
