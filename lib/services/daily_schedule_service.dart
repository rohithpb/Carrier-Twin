class DailyTaskItem {
  final String id;
  final int semester;
  final int dayNumber;
  final String title;
  final String category;
  final String subtitle;
  final int estimatedMinutes;
  final int readinessBoost;
  bool isCompleted;

  DailyTaskItem({
    required this.id,
    required this.semester,
    required this.dayNumber,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.estimatedMinutes,
    required this.readinessBoost,
    this.isCompleted = false,
  });
}

class DailyScheduleService {
  /// Generate semester-specific day-by-day study schedule
  static List<DailyTaskItem> getTasksForSemester({
    required int semester,
    required String targetRole,
    int currentDay = 14,
    List<String> completedIds = const [],
  }) {
    final List<DailyTaskItem> allTasks = [];

    if (semester <= 2) {
      // Semesters 1 & 2: Fundamentals & Programming Foundations
      allTasks.addAll([
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_1',
          semester: semester,
          dayNumber: currentDay,
          title: 'C Programming & Logic Building Module',
          category: 'Core Academics',
          subtitle: 'University Subject • Pointers & Memory Structures',
          estimatedMinutes: 30,
          readinessBoost: 2,
        ),
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_2',
          semester: semester,
          dayNumber: currentDay,
          title: 'Solve 2 HackerRank Array Problems',
          category: 'Coding Practice',
          subtitle: 'Basic Problem Solving • 20 mins',
          estimatedMinutes: 20,
          readinessBoost: 3,
        ),
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_3',
          semester: semester,
          dayNumber: currentDay,
          title: 'Git & GitHub Basics Hands-on',
          category: 'Workshop',
          subtitle: 'Create repo & commit first project',
          estimatedMinutes: 25,
          readinessBoost: 2,
        ),
      ]);
    } else if (semester <= 4) {
      // Semesters 3 & 4: Core Data Structures, DBMS & NPTEL Certification
      allTasks.addAll([
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_1',
          semester: semester,
          dayNumber: currentDay,
          title: 'NPTEL Swayam Video Lecture: Python for Data Science',
          category: 'NPTEL Course',
          subtitle: 'IIT Madras • Week 4 Assignment Review',
          estimatedMinutes: 35,
          readinessBoost: 3,
        ),
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_2',
          semester: semester,
          dayNumber: currentDay,
          title: 'Solve 2 LeetCode Tree & DBMS Query Problems',
          category: 'Coding Practice',
          subtitle: 'Campus Placement Technical Round Prep',
          estimatedMinutes: 30,
          readinessBoost: 4,
        ),
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_3',
          semester: semester,
          dayNumber: currentDay,
          title: 'Register for AI & Cloud Workshop',
          category: 'Workshop',
          subtitle: 'Hands-on Session with AWS & Firebase',
          estimatedMinutes: 15,
          readinessBoost: 2,
        ),
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_4',
          semester: semester,
          dayNumber: currentDay,
          title: 'DBMS Normalization Series Exam Review',
          category: 'Exam Prep',
          subtitle: 'University Internal Exam • 3NF & BCNF',
          estimatedMinutes: 25,
          readinessBoost: 2,
        ),
      ]);
    } else if (semester <= 6) {
      // Semesters 5 & 6: Advanced Specialization & Mock Interviews
      allTasks.addAll([
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_1',
          semester: semester,
          dayNumber: currentDay,
          title: 'Complete $targetRole Capstone Module',
          category: 'Specialization',
          subtitle: 'Building verified full-stack project repo',
          estimatedMinutes: 40,
          readinessBoost: 4,
        ),
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_2',
          semester: semester,
          dayNumber: currentDay,
          title: 'Mock Placement AI Technical Interview',
          category: 'Placement Prep',
          subtitle: 'TCS Digital / Cognizant GenC Pattern',
          estimatedMinutes: 25,
          readinessBoost: 5,
        ),
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_3',
          semester: semester,
          dayNumber: currentDay,
          title: 'Update Single-Page ATS Resume with Projects',
          category: 'Resume Milestone',
          subtitle: 'Verified GitHub link & CGPA sync',
          estimatedMinutes: 20,
          readinessBoost: 3,
        ),
      ]);
    } else {
      // Semesters 7 & 8: Campus Drives & Internship Onboarding
      allTasks.addAll([
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_1',
          semester: semester,
          dayNumber: currentDay,
          title: 'Apply for On-Campus Placement Drives',
          category: 'Placement Drive',
          subtitle: 'TechCorp Solutions & CloudScale Systems',
          estimatedMinutes: 20,
          readinessBoost: 5,
        ),
        DailyTaskItem(
          id: 'sem${semester}_day${currentDay}_2',
          semester: semester,
          dayNumber: currentDay,
          title: 'System Design & Code Refactoring Practice',
          category: 'Coding Practice',
          subtitle: 'L2 Technical Interview Prep',
          estimatedMinutes: 35,
          readinessBoost: 4,
        ),
      ]);
    }

    // Update completed status based on stored list
    for (var task in allTasks) {
      if (completedIds.contains(task.id)) {
        task.isCompleted = true;
      }
    }

    return allTasks;
  }
}
