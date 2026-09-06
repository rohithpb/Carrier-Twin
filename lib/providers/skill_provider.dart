import 'package:flutter/material.dart';
import '../models/skill_tree.dart';
import '../services/firestore_service.dart';

class SkillProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  CareerPathSkillTree? _currentSkillTree;
  bool _isLoading = false;
  String _activePath = 'Full Stack Development';

  CareerPathSkillTree? get currentSkillTree => _currentSkillTree;
  bool get isLoading => _isLoading;
  String get activePath => _activePath;

  double get progressPercentage {
    if (_currentSkillTree == null || _currentSkillTree!.skills.isEmpty) return 0.0;
    final completed = _currentSkillTree!.skills.where((s) => s.isCompleted).length;
    return completed / _currentSkillTree!.skills.length;
  }

  int get totalEstimatedHours {
    if (_currentSkillTree == null) return 0;
    return _currentSkillTree!.skills.fold(0, (sum, s) => sum + s.estimatedHours);
  }

  Future<void> loadSkillTree(String careerPath, List<String> userCompletedSkillIds) async {
    _isLoading = true;
    _activePath = careerPath;
    notifyListeners();

    final tree = await _firestoreService.getSkillTreeForPath(careerPath);
    
    // Sync completion status from student profile
    for (var skill in tree.skills) {
      skill.isCompleted = userCompletedSkillIds.contains(skill.id);
    }

    _currentSkillTree = tree;
    _isLoading = false;
    notifyListeners();
  }

  void toggleSkillMastery(String skillId) {
    if (_currentSkillTree == null) return;
    for (var skill in _currentSkillTree!.skills) {
      if (skill.id == skillId) {
        skill.isCompleted = !skill.isCompleted;
        break;
      }
    }
    notifyListeners();
  }
}
