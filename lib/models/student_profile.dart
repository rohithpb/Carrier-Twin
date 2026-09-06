class StudentProfile {
  final String uid;
  final String email;
  final String displayName;
  final String careerPath; // Full Stack, Web Development, Cloud Computing, Machine Learning
  final double currentGpa;
  final double targetGpa;
  final double weeklyStudyHours;
  final double certPrepHours;
  final int stressLevel; // 1-10 scale
  final int currentSemesterNum; // 1 to 8
  final String departmentName;
  final List<String> completedSkillIds;
  final List<String> completedDailyTaskIds;
  final Map<String, int> skillProficiencies; // e.g. {"Frontend": 3, "Backend": 2, ...}

  String get name => displayName.isEmpty ? 'Arjun Nair' : displayName;
  String get rollNumber => "CS22B042";
  String get department => (departmentName.isEmpty) ? "B.Tech CSE" : departmentName;
  String get batch => "2022–26";
  String get semester => "Semester $currentSemesterNum";
  double get cgpa => currentGpa > 4.0 ? currentGpa : 8.42;
  int get activeBacklogs => 0;

  StudentProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.careerPath,
    this.currentGpa = 3.40,
    this.targetGpa = 3.80,
    this.weeklyStudyHours = 18.0,
    this.certPrepHours = 6.0,
    this.stressLevel = 5,
    this.currentSemesterNum = 4,
    this.departmentName = "B.Tech CSE",
    List<String>? completedSkillIds,
    List<String>? completedDailyTaskIds,
    Map<String, int>? skillProficiencies,
  })  : completedSkillIds = completedSkillIds ?? [],
        completedDailyTaskIds = completedDailyTaskIds ?? ['day14_task1'],
        skillProficiencies = skillProficiencies ?? {
          "Frontend": 3,
          "Backend": 2,
          "Cloud": 1,
          "ML": 0,
          "DevOps": 1,
        };

  StudentProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? careerPath,
    double? currentGpa,
    double? targetGpa,
    double? weeklyStudyHours,
    double? certPrepHours,
    int? stressLevel,
    int? currentSemesterNum,
    String? departmentName,
    List<String>? completedSkillIds,
    List<String>? completedDailyTaskIds,
    Map<String, int>? skillProficiencies,
  }) {
    return StudentProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      careerPath: careerPath ?? this.careerPath,
      currentGpa: currentGpa ?? this.currentGpa,
      targetGpa: targetGpa ?? this.targetGpa,
      weeklyStudyHours: weeklyStudyHours ?? this.weeklyStudyHours,
      certPrepHours: certPrepHours ?? this.certPrepHours,
      stressLevel: stressLevel ?? this.stressLevel,
      currentSemesterNum: currentSemesterNum ?? this.currentSemesterNum,
      departmentName: departmentName ?? this.departmentName,
      completedSkillIds: completedSkillIds ?? List.from(this.completedSkillIds),
      completedDailyTaskIds: completedDailyTaskIds ?? List.from(this.completedDailyTaskIds),
      skillProficiencies: skillProficiencies ?? Map.from(this.skillProficiencies),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'careerPath': careerPath,
      'currentGpa': currentGpa,
      'targetGpa': targetGpa,
      'weeklyStudyHours': weeklyStudyHours,
      'certPrepHours': certPrepHours,
      'stressLevel': stressLevel,
      'currentSemesterNum': currentSemesterNum,
      'departmentName': departmentName,
      'completedSkillIds': completedSkillIds,
      'completedDailyTaskIds': completedDailyTaskIds,
      'skillProficiencies': skillProficiencies,
    };
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map, String uid) {
    return StudentProfile(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Student',
      careerPath: map['careerPath'] ?? 'Full Stack Development',
      currentGpa: (map['currentGpa'] ?? 3.40).toDouble(),
      targetGpa: (map['targetGpa'] ?? 3.80).toDouble(),
      weeklyStudyHours: (map['weeklyStudyHours'] ?? 18.0).toDouble(),
      certPrepHours: (map['certPrepHours'] ?? 6.0).toDouble(),
      stressLevel: (map['stressLevel'] ?? 5).toInt(),
      currentSemesterNum: (map['currentSemesterNum'] ?? 4).toInt(),
      departmentName: (map['departmentName'] ?? map['department'] ?? 'Computer Science').toString(),
      completedSkillIds: List<String>.from(map['completedSkillIds'] ?? []),
      completedDailyTaskIds: List<String>.from(map['completedDailyTaskIds'] ?? []),
      skillProficiencies: Map<String, int>.from(map['skillProficiencies'] ?? {}),
    );
  }
}
