class SkillNode {
  final String id;
  final String title;
  final String category; // e.g., Frontend, Backend, DevOps, Data Science
  final String description;
  final String difficulty; // Beginner, Intermediate, Advanced
  final int estimatedHours;
  bool isCompleted;
  final List<String> prerequisites;

  SkillNode({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.difficulty,
    required this.estimatedHours,
    this.isCompleted = false,
    this.prerequisites = const [],
  });

  SkillNode copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    String? difficulty,
    int? estimatedHours,
    bool? isCompleted,
    List<String>? prerequisites,
  }) {
    return SkillNode(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      isCompleted: isCompleted ?? this.isCompleted,
      prerequisites: prerequisites ?? List.from(this.prerequisites),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'difficulty': difficulty,
      'estimatedHours': estimatedHours,
      'isCompleted': isCompleted,
      'prerequisites': prerequisites,
    };
  }

  factory SkillNode.fromMap(Map<String, dynamic> map) {
    return SkillNode(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'General',
      description: map['description'] ?? '',
      difficulty: map['difficulty'] ?? 'Beginner',
      estimatedHours: (map['estimatedHours'] ?? 10).toInt(),
      isCompleted: map['isCompleted'] ?? false,
      prerequisites: List<String>.from(map['prerequisites'] ?? []),
    );
  }
}

class CareerPathSkillTree {
  final String pathId;
  final String title;
  final String description;
  final String iconName;
  final List<SkillNode> skills;

  CareerPathSkillTree({
    required this.pathId,
    required this.title,
    required this.description,
    required this.iconName,
    required this.skills,
  });
}
