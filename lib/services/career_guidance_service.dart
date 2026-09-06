import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_role.dart';
import '../models/learning_resource.dart';
import '../models/student_profile.dart';
import 'ai_model_service.dart';

class SkillGapAnalysis {
  final JobRole targetRole;
  final double readinessPercentage;
  final List<String> acquiredSkills;
  final List<String> missingSkills;

  SkillGapAnalysis({
    required this.targetRole,
    required this.readinessPercentage,
    required this.acquiredSkills,
    required this.missingSkills,
  });
}

class CareerGuidanceService {
  /// Catalog of curated industry job roles
  static final List<JobRole> defaultJobRoles = [
    const JobRole(
      id: 'fullstack_dev',
      title: 'Full-Stack Software Engineer',
      category: 'Software Engineering',
      description: 'Build web & mobile apps end-to-end using modern frontend & backend tech stacks.',
      salaryRange: '₹8 - 20 LPA',
      demandLevel: 'Very High',
      requiredSkills: ['Flutter', 'Node.js', 'PostgreSQL', 'REST APIs', 'Docker', 'Git'],
      keyResponsibilities: ['Develop responsive UIs', 'Design database schemas', 'Deploy cloud APIs'],
      iconName: 'code',
    ),
    const JobRole(
      id: 'aiml_engineer',
      title: 'AI / Machine Learning Engineer',
      category: 'Artificial Intelligence',
      description: 'Develop predictive models, fine-tune LLMs, and deploy AI pipelines into production.',
      salaryRange: '₹12 - 28 LPA',
      demandLevel: 'Critical',
      requiredSkills: ['Python', 'PyTorch / TensorFlow', 'Scikit-Learn', 'Data Processing', 'MLOps', 'SQL'],
      keyResponsibilities: ['Train neural networks', 'Process large datasets', 'Deploy ML microservices'],
      iconName: 'psychology',
    ),
    const JobRole(
      id: 'cloud_devops',
      title: 'Cloud & DevOps Engineer',
      category: 'Cloud Computing',
      description: 'Automate deployment pipelines, manage AWS/GCP infrastructure, and ensure high availability.',
      salaryRange: '₹10 - 24 LPA',
      demandLevel: 'High',
      requiredSkills: ['AWS', 'Docker', 'Kubernetes', 'CI/CD Pipelines', 'Linux', 'Terraform'],
      keyResponsibilities: ['Configure Kubernetes clusters', 'Automate builds with CI/CD', 'Monitor cloud security'],
      iconName: 'cloud',
    ),
    const JobRole(
      id: 'cybersecurity',
      title: 'Cybersecurity & PenTester',
      category: 'Security',
      description: 'Protect enterprise infrastructure, conduct vulnerability assessments, and secure APIs.',
      salaryRange: '₹9 - 22 LPA',
      demandLevel: 'High',
      requiredSkills: ['Ethical Hacking', 'Network Security', 'OWASP Top 10', 'Python', 'Linux', 'Cryptography'],
      keyResponsibilities: ['Audit codebases for flaws', 'Perform penetration testing', 'Harden cloud servers'],
      iconName: 'security',
    ),
    const JobRole(
      id: 'data_scientist',
      title: 'Data Scientist & Analyst',
      category: 'Data & Analytics',
      description: 'Turn complex data into strategic business insights through statistical models & dashboards.',
      salaryRange: '₹9 - 22 LPA',
      demandLevel: 'High',
      requiredSkills: ['Python', 'SQL', 'Power BI / Tableau', 'Statistics', 'Pandas', 'Data Viz'],
      keyResponsibilities: ['Clean messy datasets', 'Build executive dashboards', 'Perform hypothesis testing'],
      iconName: 'analytics',
    ),
  ];

  /// Master Catalog of Courses
  static final List<CourseResource> _masterCourses = [
    const CourseResource(
      id: 'c1',
      title: 'NPTEL: Modern Application Development with Flutter & Node',
      platform: 'NPTEL',
      provider: 'IIT Madras',
      duration: '8 Weeks',
      skillTarget: 'Flutter',
      url: 'https://nptel.ac.in/courses/106106224',
      isFree: true,
      rating: 4.9,
    ),
    const CourseResource(
      id: 'c2',
      title: 'Node.js, Express & PostgreSQL Masterclass',
      platform: 'SWAYAM',
      provider: 'IIT Bombay',
      duration: '6 Weeks',
      skillTarget: 'Node.js',
      url: 'https://swayam.gov.in',
      isFree: true,
      rating: 4.8,
    ),
    const CourseResource(
      id: 'c3',
      title: 'Docker & Kubernetes Hands-on for Beginners',
      platform: 'Coursera',
      provider: 'Google Cloud',
      duration: '4 Weeks',
      skillTarget: 'Docker',
      url: 'https://coursera.org/learn/google-kubernetes-engine',
      isFree: true,
      rating: 4.7,
    ),
    const CourseResource(
      id: 'c4',
      title: 'Complete PyTorch for Deep Learning & Computer Vision',
      platform: 'NPTEL',
      provider: 'IIT Kharagpur',
      duration: '12 Weeks',
      skillTarget: 'PyTorch / TensorFlow',
      url: 'https://nptel.ac.in',
      isFree: true,
      rating: 4.9,
    ),
    const CourseResource(
      id: 'c5',
      title: 'AWS Certified Cloud Practitioner Bootcamp',
      platform: 'YouTube',
      provider: 'freeCodeCamp',
      duration: '14 Hours',
      skillTarget: 'AWS',
      url: 'https://youtube.com/watch?v=3hLmDS179YE',
      isFree: true,
      rating: 4.9,
    ),
    const CourseResource(
      id: 'c6',
      title: 'Ethical Hacking & Network Vulnerability Assessment',
      platform: 'SWAYAM',
      provider: 'IIT Delhi',
      duration: '8 Weeks',
      skillTarget: 'Ethical Hacking',
      url: 'https://swayam.gov.in',
      isFree: true,
      rating: 4.8,
    ),
  ];

  /// Master Catalog of Workshops
  static final List<WorkshopResource> _masterWorkshops = [
    const WorkshopResource(
      id: 'w1',
      title: '2-Day Live Docker & CI/CD Deployment Workshop',
      organizer: 'Department of Computer Science',
      date: 'Next Saturday & Sunday',
      mode: 'On-Campus Hands-on Lab',
      skillTarget: 'Docker',
      registrationUrl: 'https://college.edu/events/docker-workshop',
      isCollegeEndorsed: true,
    ),
    const WorkshopResource(
      id: 'w2',
      title: 'Building Production Flutter Apps with Clean Architecture',
      organizer: 'Google Developer Student Club (GDSC)',
      date: 'Sep 18, 2026',
      mode: 'Online Interactive',
      skillTarget: 'Flutter',
      registrationUrl: 'https://gdsc.community.dev',
      isCollegeEndorsed: true,
    ),
    const WorkshopResource(
      id: 'w3',
      title: 'Generative AI & LLM Fine-Tuning Bootcamp',
      organizer: 'AI Innovation Cell',
      date: 'Sep 22-23, 2026',
      mode: 'Hybrid Workshop',
      skillTarget: 'PyTorch / TensorFlow',
      registrationUrl: 'https://college.edu/events/genai-bootcamp',
      isCollegeEndorsed: true,
    ),
    const WorkshopResource(
      id: 'w4',
      title: 'AWS Cloud Serverless Infrastructure Workshop',
      organizer: 'Cloud Center of Excellence',
      date: 'Oct 02, 2026',
      mode: 'On-Campus Lab',
      skillTarget: 'AWS',
      registrationUrl: 'https://college.edu/events/aws-lab',
      isCollegeEndorsed: true,
    ),
  ];

  /// Master Catalog of Internships
  static final List<InternshipResource> _masterInternships = [
    const InternshipResource(
      id: 'i1',
      company: 'InnovateX Labs',
      roleTitle: 'Full-Stack Developer Intern',
      location: 'Remote / Kochi',
      stipend: '₹15,000 - ₹20,000 / month',
      duration: '3 Months',
      requiredSkills: ['Flutter', 'Node.js', 'REST APIs'],
      applyUrl: 'https://internshala.com/internship/detail/full-stack-intern-101',
      deadline: 'Applies in 5 days',
    ),
    const InternshipResource(
      id: 'i2',
      company: 'CyberGuard Security',
      roleTitle: 'Junior Security & Penetration Testing Intern',
      location: 'Bangalore / Hybrid',
      stipend: '₹18,000 / month',
      duration: '6 Months',
      requiredSkills: ['Ethical Hacking', 'Linux', 'Network Security'],
      applyUrl: 'https://linkedin.com/jobs/cyberguard-intern',
      deadline: 'Open Now',
    ),
    const InternshipResource(
      id: 'i3',
      company: 'CloudScale Technologies',
      roleTitle: 'DevOps & Cloud Automation Intern',
      location: 'Remote',
      stipend: '₹22,000 / month',
      duration: '3 Months',
      requiredSkills: ['AWS', 'Docker', 'CI/CD Pipelines'],
      applyUrl: 'https://cloudscale.io/careers/internships',
      deadline: 'Limited Seats',
    ),
    const InternshipResource(
      id: 'i4',
      company: 'DataMind Insights',
      roleTitle: 'AI / Data Science Research Intern',
      location: 'Hyderabad / Remote',
      stipend: '₹25,000 / month',
      duration: '4 Months',
      requiredSkills: ['Python', 'PyTorch / TensorFlow', 'SQL'],
      applyUrl: 'https://datamind.ai/internship',
      deadline: 'Applies in 7 days',
    ),
  ];

  /// Perform Skill Gap Analysis for Student against Target Job Role
  SkillGapAnalysis calculateSkillGap(StudentProfile profile, JobRole role) {
    // Current completed skills mapped to lower-case normalized terms
    final userSkillSet = profile.completedSkillIds.map((s) => s.toLowerCase()).toSet();
    
    // Check proficiencies map too
    profile.skillProficiencies.forEach((key, val) {
      if (val > 0) {
        userSkillSet.add(key.toLowerCase());
      }
    });

    final List<String> acquired = [];
    final List<String> missing = [];

    for (final reqSkill in role.requiredSkills) {
      final reqLower = reqSkill.toLowerCase();
      bool matched = false;

      for (final userSkill in userSkillSet) {
        if (userSkill.contains(reqLower) || reqLower.contains(userSkill)) {
          matched = true;
          break;
        }
      }

      if (matched) {
        acquired.add(reqSkill);
      } else {
        missing.add(reqSkill);
      }
    }

    // Default base readiness score if user profile has completed skills
    double readiness = role.requiredSkills.isEmpty 
        ? 1.0 
        : (acquired.length / role.requiredSkills.length);

    // Boost readiness slightly based on CGPA & study hours
    if (profile.cgpa >= 8.0) readiness += 0.05;
    if (readiness > 1.0) readiness = 1.0;

    return SkillGapAnalysis(
      targetRole: role,
      readinessPercentage: readiness * 100,
      acquiredSkills: acquired,
      missingSkills: missing,
    );
  }

  /// Get recommended courses for missing skills
  List<CourseResource> getRecommendedCourses(List<String> missingSkills) {
    if (missingSkills.isEmpty) return _masterCourses.take(3).toList();
    
    final matches = _masterCourses.where((course) {
      return missingSkills.any((skill) => 
        course.skillTarget.toLowerCase().contains(skill.toLowerCase()) ||
        skill.toLowerCase().contains(course.skillTarget.toLowerCase())
      );
    }).toList();

    return matches.isEmpty ? _masterCourses.take(4).toList() : matches;
  }

  /// Get upcoming workshops for missing skills
  List<WorkshopResource> getUpcomingWorkshops(List<String> missingSkills) {
    if (missingSkills.isEmpty) return _masterWorkshops;

    final matches = _masterWorkshops.where((ws) {
      return missingSkills.any((skill) => 
        ws.skillTarget.toLowerCase().contains(skill.toLowerCase()) ||
        skill.toLowerCase().contains(ws.skillTarget.toLowerCase())
      );
    }).toList();

    return matches.isEmpty ? _masterWorkshops : matches;
  }

  /// Get matching internships for target role
  List<InternshipResource> getMatchingInternships(JobRole targetRole) {
    return _masterInternships.where((internship) {
      return internship.requiredSkills.any((skill) => 
        targetRole.requiredSkills.any((req) => req.toLowerCase() == skill.toLowerCase())
      );
    }).toList();
  }

  /// Generate personalized 4-Week Action Plan via Multi-Model AI Service
  Future<String> generateAiRoadmap(StudentProfile profile, SkillGapAnalysis gap) async {
    try {
      final prompt = '''
You are an expert AI Career Mentor for university engineering students.
Generate a concise, actionable 4-week step-by-step learning roadmap for student ${profile.displayName} aiming for: "${gap.targetRole.title}".

Student Context:
- Department: ${profile.departmentName} (Semester ${profile.currentSemesterNum})
- Current CGPA: ${profile.cgpa.toStringAsFixed(2)}
- Acquired Skills: ${gap.acquiredSkills.join(', ')}
- Missing Skills to Achieve Role: ${gap.missingSkills.join(', ')}
- Weekly Available Prep Time: ${profile.certPrepHours} hours

Provide:
1. "🎯 Target Focus": 1 summary sentence.
2. "📅 4-Week Action Plan":
   - Week 1: Core Foundation & Course Target
   - Week 2: Hands-on Workshop / Coding Project
   - Week 3: Advanced Topic & Portfolio Integration
   - Week 4: Internship Prep & Resume Polish
3. "⚡ Pro Tip": 1 high-impact tip for landing this role.
Keep the tone encouraging, professional, and structured with clean markdown formatting.
''';

      final reply = await AiModelService().generateResponse(prompt);
      if (reply.isNotEmpty) return reply;
    } catch (e) {
      // Fallback structured text response if offline/timeout
    }

    // Dynamic local fallback plan
    final missingStr = gap.missingSkills.isEmpty ? "Advanced Architecture" : gap.missingSkills.first;
    return '''
🎯 **Target Focus**: Bridge your gap in ${gap.missingSkills.join(', ')} to achieve 100% readiness for ${gap.targetRole.title}.

📅 **4-Week Action Plan**:
• **Week 1 (Foundations)**: Enroll in the recommended NPTEL/Coursera track for **$missingStr**. Dedicate ${profile.certPrepHours.toInt()} hrs/week.
• **Week 2 (Hands-on Practice)**: Attend the upcoming weekend workshop and build a mini project using $missingStr.
• **Week 3 (Portfolio Integration)**: Push your project code to GitHub with detailed README & architectural diagrams.
• **Week 4 (Internship Drive)**: Tailor your resume ATS score for ${gap.targetRole.title} and apply to the 3 recommended internships.

⚡ **Pro Tip**: Getting mentor endorsements for your GitHub projects boosts your resume verification score by 40% during campus drives!
''';
  }
}
