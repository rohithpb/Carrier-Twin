/// Represents a Course (NPTEL, Coursera, YouTube, University)
class CourseResource {
  final String id;
  final String title;
  final String platform; // NPTEL, Coursera, YouTube, SWAYAM
  final String provider; // e.g. IIT Madras, Meta, Google
  final String duration; // e.g. "8 Weeks", "12 Hours"
  final String skillTarget; // Skill addressed e.g. "Docker", "Data Structures"
  final String url;
  final bool isFree;
  final double rating;

  const CourseResource({
    required this.id,
    required this.title,
    required this.platform,
    required this.provider,
    required this.duration,
    required this.skillTarget,
    required this.url,
    this.isFree = true,
    this.rating = 4.8,
  });

  factory CourseResource.fromMap(Map<String, dynamic> map, String id) {
    return CourseResource(
      id: id,
      title: map['title'] ?? '',
      platform: map['platform'] ?? 'NPTEL',
      provider: map['provider'] ?? 'IIT Madras',
      duration: map['duration'] ?? '8 Weeks',
      skillTarget: map['skillTarget'] ?? '',
      url: map['url'] ?? '',
      isFree: map['isFree'] ?? true,
      rating: (map['rating'] ?? 4.8).toDouble(),
    );
  }
}

/// Represents a Workshop / Bootcamp
class WorkshopResource {
  final String id;
  final String title;
  final String organizer;
  final String date;
  final String mode; // Hands-on Online, On-Campus Lab
  final String skillTarget;
  final String registrationUrl;
  final bool isCollegeEndorsed;

  const WorkshopResource({
    required this.id,
    required this.title,
    required this.organizer,
    required this.date,
    required this.mode,
    required this.skillTarget,
    required this.registrationUrl,
    this.isCollegeEndorsed = true,
  });

  factory WorkshopResource.fromMap(Map<String, dynamic> map, String id) {
    return WorkshopResource(
      id: id,
      title: map['title'] ?? '',
      organizer: map['organizer'] ?? 'Department of CSE',
      date: map['date'] ?? 'Upcoming Weekend',
      mode: map['mode'] ?? 'Hands-on Bootcamp',
      skillTarget: map['skillTarget'] ?? '',
      registrationUrl: map['registrationUrl'] ?? '',
      isCollegeEndorsed: map['isCollegeEndorsed'] ?? true,
    );
  }
}

/// Represents an Internship Opportunity
class InternshipResource {
  final String id;
  final String company;
  final String roleTitle;
  final String location; // Remote, Hybrid, Bangalore, Kochi
  final String stipend; // e.g. "₹18,000 / month"
  final String duration; // e.g. "3 Months"
  final List<String> requiredSkills;
  final String applyUrl;
  final String deadline;

  const InternshipResource({
    required this.id,
    required this.company,
    required this.roleTitle,
    required this.location,
    required this.stipend,
    required this.duration,
    required this.requiredSkills,
    required this.applyUrl,
    required this.deadline,
  });

  factory InternshipResource.fromMap(Map<String, dynamic> map, String id) {
    return InternshipResource(
      id: id,
      company: map['company'] ?? '',
      roleTitle: map['roleTitle'] ?? '',
      location: map['location'] ?? 'Remote',
      stipend: map['stipend'] ?? 'Stipend Provided',
      duration: map['duration'] ?? '3 Months',
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      applyUrl: map['applyUrl'] ?? '',
      deadline: map['deadline'] ?? 'Apply Soon',
    );
  }
}
