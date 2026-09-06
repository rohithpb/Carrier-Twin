import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class FacultyProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? facultyData;
  final String userId;

  const FacultyProfileScreen({
    super.key,
    this.facultyData,
    this.userId = '',
  });

  static const Map<String, Map<String, dynamic>> _facultyRegistry = {
    'FAC-CSE-0914': {
      'name': 'Dr. Priya Nair',
      'username': 'FAC-CSE-0914',
      'department': 'Computer Science & Engineering',
      'designation': 'Associate Professor & HOD',
      'college': 'Jyothi Engineering College (JECC)',
      'assigned_class': 'CS 2023-2027 (Year 2 - S4)',
      'email': 'priya.nair@jecc.ac.in',
      'mentee_count': 6,
      'avg_readiness': 78.3,
    },
    'FAC-IT-0412': {
      'name': 'Prof. Rajesh Kumar',
      'username': 'FAC-IT-0412',
      'department': 'Information Technology',
      'designation': 'Assistant Professor',
      'college': 'Govt Engineering College Thrissur (GECT)',
      'assigned_class': 'IT 2022-2026 (Year 3 - S6)',
      'email': 'rajesh.k@gect.ac.in',
      'mentee_count': 6,
      'avg_readiness': 81.0,
    },
    'FAC-BCA-0881': {
      'name': 'Dr. Manoj Pillai',
      'username': 'FAC-BCA-0881',
      'department': 'BCA Dept',
      'designation': 'Senior Lecturer',
      'college': 'Mar Athanasius College (MACE)',
      'assigned_class': 'BCA 2023-2026 (Year 2 - S4)',
      'email': 'manoj.p@mace.ac.in',
      'mentee_count': 6,
      'avg_readiness': 75.5,
    },
    'FAC-ECE-0315': {
      'name': 'Prof. Anitha Varghese',
      'username': 'FAC-ECE-0315',
      'department': 'Electronics & Communication',
      'designation': 'Associate Professor',
      'college': 'Jyothi Engineering College (JECC)',
      'assigned_class': 'ECE 2022-2026 (Year 3 - S6)',
      'email': 'anitha.v@jecc.ac.in',
      'mentee_count': 5,
      'avg_readiness': 77.2,
    },
    'FAC-CSE-0101': {
      'name': 'Dr. Suresh Menon',
      'username': 'FAC-CSE-0101',
      'department': 'Computer Science Dept',
      'designation': 'Professor & Placement Coordinator',
      'college': 'Govt Engineering College Thrissur (GECT)',
      'assigned_class': 'CS 2021-2025 (Year 4 - S8)',
      'email': 'suresh.m@gect.ac.in',
      'mentee_count': 7,
      'avg_readiness': 86.4,
    },
  };

  @override
  Widget build(BuildContext context) {
    final cleanId = userId.trim().toUpperCase();
    final matched = _facultyRegistry[cleanId] ?? facultyData;

    final name = matched?['name'] ?? 'Dr. Priya Nair';
    final empId = matched?['username'] ?? (cleanId.isEmpty ? 'FAC-CSE-0914' : cleanId);
    final dept = matched?['department'] ?? 'Computer Science & Engineering';
    final desig = matched?['designation'] ?? 'Associate Professor & HOD';
    final college = matched?['college'] ?? 'Jyothi Engineering College (JECC)';
    final assignedClass = matched?['assigned_class'] ?? 'CS 2023-2027 (Year 2 - S4)';
    final facultyEmail = matched?['email'] ?? 'priya.nair@jecc.ac.in';
    final menteeCount = matched?['mentee_count'] ?? 6;
    final avgReadiness = matched?['avg_readiness'] ?? 78.3;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Faculty Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E3DC)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.school, size: 32, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryFixed,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Faculty Mentor',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onPrimaryFixed),
                                    ),
                                  ),
                                ],
                              ),
                              Text('$empId • $desig', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                              Text('$dept, $college', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildProfileStatCard('Institution', 'JECC', 'Accredited'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildProfileStatCard('Mentees', '$menteeCount Students', 'Assigned'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildProfileStatCard('Class Readiness', '$avgReadiness%', 'Target 80%'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mentor Academic Duties & Class Batch Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E3DC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.assignment_turned_in, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Mentorship Portfolio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.groups, 'Assigned Batch', assignedClass),
                    _buildDetailRow(Icons.access_time, 'Office Hours', 'Mon & Wed 02:00 PM - 04:00 PM (CS Lab 3)'),
                    _buildDetailRow(Icons.mail_outline, 'Faculty Email', facultyEmail),
                    _buildDetailRow(Icons.workspace_premium, 'Curriculum Role', 'NPTEL swayams Coordinator & Placement Reviewer'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout / Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully from Faculty Portal.'),
                        backgroundColor: Colors.blueGrey,
                      ),
                    );
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text(
                    'Logout / Sign Out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStatCard(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: AppColors.outline, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.tertiary, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
