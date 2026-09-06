import 'package:flutter/material.dart';
import '../models/student_profile.dart';
import '../models/simulation.dart';
import '../models/mentor.dart';
import '../services/firestore_service.dart';
import '../services/cloud_function_service.dart';

import '../models/job_role.dart';
import '../models/learning_resource.dart';
import '../services/career_guidance_service.dart';

import '../services/api_service.dart';

class StudentProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final CloudFunctionService _cloudFunctionService = CloudFunctionService();
  final CareerGuidanceService _guidanceService = CareerGuidanceService();
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _backendDigitalTwin;
  Map<String, dynamic>? _backendRecommendations;
  List<dynamic> _backendPredictedRoles = [];
  bool _isLoadingBackendData = false;

  Map<String, dynamic>? get backendDigitalTwin => _backendDigitalTwin;
  Map<String, dynamic>? get backendRecommendations => _backendRecommendations;
  List<dynamic> get backendPredictedRoles => _backendPredictedRoles;
  bool get isLoadingBackendData => _isLoadingBackendData;

  late JobRole _selectedJobRole;
  SkillGapAnalysis? _skillGapAnalysis;
  String? _aiRoadmapText;
  bool _isLoadingAiRoadmap = false;

  JobRole get selectedJobRole => _selectedJobRole;
  SkillGapAnalysis? get skillGapAnalysis => _skillGapAnalysis;
  String? get aiRoadmapText => _aiRoadmapText;
  bool get isLoadingAiRoadmap => _isLoadingAiRoadmap;
  List<JobRole> get availableJobRoles => CareerGuidanceService.defaultJobRoles;

  StudentProfile _profile = StudentProfile(
    uid: 'student001',
    email: 'arjun.nair@jecc.ac.in',
    displayName: 'Arjun Nair',
    careerPath: 'Data Analyst',
    currentGpa: 8.45,
    targetGpa: 9.00,
    weeklyStudyHours: 18.0,
    certPrepHours: 8.0,
    stressLevel: 4,
  );

  SimulationResult? _latestSimulation;
  List<Mentor> _matchedMentors = [];
  bool _isSimulating = false;
  bool _isMatchingMentors = false;

  StudentProfile get profile => _profile;
  SimulationResult? get latestSimulation => _latestSimulation;
  List<Mentor> get matchedMentors => _matchedMentors;
  bool get isSimulating => _isSimulating;
  bool get isMatchingMentors => _isMatchingMentors;

  // Selected Career Path
  String get selectedPath => _profile.careerPath;

  StudentProvider() {
    _selectedJobRole = CareerGuidanceService.defaultJobRoles.first;
    _recalculateGuidance();
    loadStudentProfile('demo_user_001');
  }

  void _recalculateGuidance() {
    _skillGapAnalysis = _guidanceService.calculateSkillGap(_profile, _selectedJobRole);
  }

  void selectJobRole(JobRole role) {
    _selectedJobRole = role;
    _profile = _profile.copyWith(careerPath: role.title);
    _recalculateGuidance();
    _aiRoadmapText = null; // Reset roadmap on role change
    _firestoreService.saveStudentProfile(_profile);
    notifyListeners();
  }

  Future<void> fetchAiRoadmap() async {
    if (_skillGapAnalysis == null) return;
    _isLoadingAiRoadmap = true;
    notifyListeners();

    try {
      final text = await _guidanceService.generateAiRoadmap(_profile, _skillGapAnalysis!);
      _aiRoadmapText = text;
    } catch (e) {
      _aiRoadmapText = 'Unable to generate AI Roadmap. Please try again.';
    } finally {
      _isLoadingAiRoadmap = false;
      notifyListeners();
    }
  }

  List<CourseResource> get recommendedCourses =>
      _guidanceService.getRecommendedCourses(_skillGapAnalysis?.missingSkills ?? []);

  List<WorkshopResource> get upcomingWorkshops =>
      _guidanceService.getUpcomingWorkshops(_skillGapAnalysis?.missingSkills ?? []);

  List<InternshipResource> get matchingInternships =>
      _guidanceService.getMatchingInternships(_selectedJobRole);


  Future<void> loadStudentProfile(String uidOrUsername) async {
    final cleanId = uidOrUsername.trim().toUpperCase();

    // 1. Ensure Firestore default collections and all student accounts are seeded
    try {
      await _firestoreService.seedFirestoreCollections();
    } catch (_) {}

    // 2. Fetch directly from Firebase Firestore 'students' or 'users' collection
    try {
      final fetchedFirestoreProfile = await _firestoreService.getStudentProfile(cleanId);
      if (fetchedFirestoreProfile != null) {
        _profile = fetchedFirestoreProfile;
      } else {
        // Search Firestore students collection for ID, username, or email match
        final firestoreStudents = await _firestoreService.getStudentsFromFirestore();
        final match = firestoreStudents.firstWhere(
          (s) =>
              (s['id'] ?? '').toString().toUpperCase() == cleanId ||
              (s['email'] ?? '').toString().toUpperCase().contains(cleanId),
          orElse: () => {},
        );

        if (match.isNotEmpty) {
          final email = match['email'] ?? '';
          String deptName = match['department'] ?? 'Computer Science';

          _profile = _profile.copyWith(
            uid: match['id'] ?? cleanId,
            email: email,
            displayName: match['name'] ?? _profile.displayName,
            careerPath: match['target_role'] ?? _profile.careerPath,
            currentGpa: (match['cgpa'] ?? _profile.currentGpa).toDouble(),
            currentSemesterNum: (match['current_semester'] ?? 1).toInt(),
            departmentName: deptName,
          );
        }
      }
    } catch (e) {
      debugPrint('Firestore lookup error: $e');
    }

    // 3. Optional local API server fallback sync
    await fetchBackendData(cleanId.isEmpty ? 'student001' : cleanId);

    // 4. Save synced state back to Firebase Firestore
    try {
      await _firestoreService.saveStudentProfile(_profile);
    } catch (_) {}

    await runSimulation();
    notifyListeners();
  }

  Future<void> fetchBackendData(String studentId) async {
    _isLoadingBackendData = true;
    notifyListeners();

    try {
      final twin = await _apiService.getDigitalTwin(studentId);
      if (twin != null) {
        _backendDigitalTwin = twin;
        _profile = _profile.copyWith(
          displayName: twin['student'] ?? _profile.displayName,
          careerPath: twin['target_role'] ?? _profile.careerPath,
          currentGpa: (twin['cgpa'] ?? _profile.currentGpa).toDouble(),
        );
      }

      final recs = await _apiService.getRecommendations(studentId);
      if (recs != null) {
        _backendRecommendations = recs;
      }

      final preds = await _apiService.predictCareer(studentId);
      if (preds != null && preds['predicted_roles'] != null) {
        _backendPredictedRoles = preds['predicted_roles'];
      }
    } catch (e) {
      debugPrint('Error fetching backend data: $e');
    } finally {
      _isLoadingBackendData = false;
      notifyListeners();
    }
  }

  Future<void> addActivityToBackend(String studentId, Map<String, dynamic> activityData) async {
    final result = await _apiService.addActivity(studentId, activityData);
    if (result != null) {
      await fetchBackendData(studentId);
    }
  }

  void updateCareerPath(String pathTitle) {
    _profile = _profile.copyWith(careerPath: pathTitle);
    _firestoreService.saveStudentProfile(_profile);
    runSimulation();
    notifyListeners();
  }

  void updateAcademicSetup({
    required int currentSemesterNum,
    required String departmentName,
    required String targetRole,
    required double currentGpa,
    required double targetGpa,
    required double dailyHours,
  }) {
    _profile = _profile.copyWith(
      currentSemesterNum: currentSemesterNum,
      departmentName: departmentName,
      careerPath: targetRole,
      currentGpa: currentGpa,
      targetGpa: targetGpa,
      weeklyStudyHours: dailyHours * 7.0,
    );

    if (_backendDigitalTwin != null) {
      _backendDigitalTwin!['target_role'] = targetRole;
      _backendDigitalTwin!['cgpa'] = currentGpa;
      _backendDigitalTwin!['current_semester'] = currentSemesterNum;
    }

    _firestoreService.saveStudentProfile(_profile);
    _recalculateGuidance();
    runSimulation();
    notifyListeners();
  }

  void toggleDailyTask(String taskId, int boostAmount) {
    final List<String> currentDaily = List.from(_profile.completedDailyTaskIds);
    final bool isCompleted = currentDaily.contains(taskId);

    if (isCompleted) {
      currentDaily.remove(taskId);
    } else {
      currentDaily.add(taskId);
    }

    _profile = _profile.copyWith(completedDailyTaskIds: currentDaily);

    // Update backend Digital Twin readiness score in memory
    if (_backendDigitalTwin != null) {
      int currentReadiness = _backendDigitalTwin!['career_readiness'] as int? ?? 74;
      if (!isCompleted) {
        currentReadiness = (currentReadiness + boostAmount).clamp(0, 100);
      } else {
        currentReadiness = (currentReadiness - boostAmount).clamp(0, 100);
      }
      _backendDigitalTwin!['career_readiness'] = currentReadiness;
    }

    _firestoreService.saveStudentProfile(_profile);
    notifyListeners();
  }

  void addCustomDailyTask(String taskTitle) {
    final customId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final List<String> currentDaily = List.from(_profile.completedDailyTaskIds);
    currentDaily.add(customId);
    _profile = _profile.copyWith(completedDailyTaskIds: currentDaily);
    notifyListeners();
  }

  void updateMetrics({
    double? currentGpa,
    double? weeklyStudyHours,
    double? certPrepHours,
    int? stressLevel,
  }) {
    _profile = _profile.copyWith(
      currentGpa: currentGpa ?? _profile.currentGpa,
      weeklyStudyHours: weeklyStudyHours ?? _profile.weeklyStudyHours,
      certPrepHours: certPrepHours ?? _profile.certPrepHours,
      stressLevel: stressLevel ?? _profile.stressLevel,
    );
    _firestoreService.saveStudentProfile(_profile);
    runSimulation();
    notifyListeners();
  }

  /// Feature 4 & 5: Run GPA Impact & Workload Simulator
  Future<void> runSimulation() async {
    _isSimulating = true;
    notifyListeners();

    try {
      final result = await _cloudFunctionService.predictGpaImpact(
        currentGpa: _profile.currentGpa,
        weeklyStudyHours: _profile.weeklyStudyHours,
        certPrepHours: _profile.certPrepHours,
        stressLevel: _profile.stressLevel,
        activeSkillsCount: _profile.completedSkillIds.length,
      );
      _latestSimulation = result;
    } catch (e) {
      // Handled via fallback inside CloudFunctionService
    } finally {
      _isSimulating = false;
      notifyListeners();
    }
  }

  /// Feature 6: Mentor Match Engine
  Future<void> findMatchedMentors() async {
    _isMatchingMentors = true;
    notifyListeners();

    try {
      final Map<String, int> profs = _profile.skillProficiencies;
      final List<int> vector = [
        profs['Frontend'] ?? 3,
        profs['Backend'] ?? 2,
        profs['Cloud'] ?? 1,
        profs['ML'] ?? 0,
        profs['DevOps'] ?? 1,
      ];

      final mentors = await _cloudFunctionService.matchMentors(skillVector: vector);
      _matchedMentors = mentors;
    } catch (e) {
      // Handled inside service
    } finally {
      _isMatchingMentors = false;
      notifyListeners();
    }
  }

  void toggleSkillCompletion(String skillId) {
    final List<String> currentSkills = List.from(_profile.completedSkillIds);
    if (currentSkills.contains(skillId)) {
      currentSkills.remove(skillId);
    } else {
      currentSkills.add(skillId);
    }
    _profile = _profile.copyWith(completedSkillIds: currentSkills);
    _recalculateGuidance();
    _firestoreService.saveStudentProfile(_profile);
    runSimulation();
    notifyListeners();
  }
}

