class Mentor {
  final String id;
  final String name;
  final String role;
  final String path;
  final String avatarUrl;
  final List<String> skills;
  final String bio;
  final int matchPercentage;

  Mentor({
    required this.id,
    required this.name,
    required this.role,
    required this.path,
    required this.avatarUrl,
    required this.skills,
    required this.bio,
    this.matchPercentage = 85,
  });

  factory Mentor.fromMap(Map<String, dynamic> map) {
    return Mentor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      path: map['path'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      bio: map['bio'] ?? '',
      matchPercentage: (map['matchPercentage'] ?? 80).toInt(),
    );
  }
}
