class JobRole {
  final String id;
  final String title;
  final String category;
  final String description;
  final String salaryRange;
  final String demandLevel; // High, Very High, Critical
  final List<String> requiredSkills;
  final List<String> keyResponsibilities;
  final String iconName;

  const JobRole({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.salaryRange,
    required this.demandLevel,
    required this.requiredSkills,
    required this.keyResponsibilities,
    required this.iconName,
  });

  factory JobRole.fromMap(Map<String, dynamic> map, String id) {
    return JobRole(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? 'Engineering',
      description: map['description'] ?? '',
      salaryRange: map['salaryRange'] ?? '₹8 - 18 LPA',
      demandLevel: map['demandLevel'] ?? 'High',
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      keyResponsibilities: List<String>.from(map['keyResponsibilities'] ?? []),
      iconName: map['iconName'] ?? 'code',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'salaryRange': salaryRange,
      'demandLevel': demandLevel,
      'requiredSkills': requiredSkills,
      'keyResponsibilities': keyResponsibilities,
      'iconName': iconName,
    };
  }
}
