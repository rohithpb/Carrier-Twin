import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class RecruiterProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? recruiterData;
  final String userId;

  const RecruiterProfileScreen({
    super.key,
    this.recruiterData,
    this.userId = '',
  });

  static const Map<String, Map<String, dynamic>> _recruiterRegistry = {
    'REC-TNP-001': {
      'name': 'Ananya Sharma',
      'username': 'REC-TNP-001',
      'company': 'TechCorp Solutions',
      'designation': 'Senior Technical Recruiter',
      'email': 'ananya.s@techcorp.com',
      'target_role': 'Data Analyst',
    },
    'REC-TNP-002': {
      'name': 'Karthik Raja',
      'username': 'REC-TNP-002',
      'company': 'CloudScale Systems',
      'designation': 'Lead Cloud Talent Specialist',
      'email': 'karthik.r@cloudscale.io',
      'target_role': 'Cloud Engineer',
    },
    'REC-TNP-003': {
      'name': 'Vikram Sethi',
      'username': 'REC-TNP-003',
      'company': 'Innovate AI Labs',
      'designation': 'Engineering Hiring Manager',
      'email': 'vikram.s@innovateai.labs',
      'target_role': 'Machine Learning Engineer',
    },
    'REC-TNP-004': {
      'name': 'Deepa Sundaram',
      'username': 'REC-TNP-004',
      'company': 'CodeKraft Global',
      'designation': 'Head of Campus Hiring',
      'email': 'deepa.s@codekraft.tech',
      'target_role': 'Full Stack Developer',
    },
    'REC-TNP-005': {
      'name': 'Rohan Deshmukh',
      'username': 'REC-TNP-005',
      'company': 'CyberGuard Security',
      'designation': 'Lead Security Recruiter',
      'email': 'rohan.d@cyberguard.sec',
      'target_role': 'Cybersecurity Analyst',
    },
    'REC-TNP-006': {
      'name': 'Priya Nair',
      'username': 'REC-TNP-006',
      'company': 'MobilePro Digital',
      'designation': 'Mobile Hiring Lead',
      'email': 'priya.n@mobileapps.co',
      'target_role': 'Mobile App Developer',
    },
    'REC-TNP-007': {
      'name': 'Arun Varma',
      'username': 'REC-TNP-007',
      'company': 'InfraScale DevOps',
      'designation': 'DevOps Talent Director',
      'email': 'arun.v@devopsops.io',
      'target_role': 'DevOps Engineer',
    },
  };

  @override
  Widget build(BuildContext context) {
    final cleanId = userId.trim().toUpperCase();
    final matched = _recruiterRegistry[cleanId] ?? recruiterData;

    final name = matched?['name'] ?? 'Ananya Sharma';
    final recId = matched?['username'] ?? (cleanId.isEmpty ? 'REC-TNP-001' : cleanId);
    final company = matched?['company'] ?? 'TechCorp Solutions';
    final desig = matched?['designation'] ?? 'Lead Technical Recruiter';
    final recEmail = matched?['email'] ?? 'ananya.s@techcorp.com';
    final collegeHub = matched?['college'] ?? 'Associated Partner Institutions (JECC, GECT, MACE)';
    final targetRole = matched?['target_role'] ?? 'Data Analyst & Cloud Engineers';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recruiter Header Card
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
                          backgroundColor: AppColors.tertiary,
                          child: const Icon(Icons.corporate_fare, size: 32, color: Colors.white),
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
                                      color: AppColors.tertiaryFixed,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Recruiter / T&P',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onTertiaryFixed),
                                    ),
                                  ),
                                ],
                              ),
                              Text('$recId • $desig', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                              Text(company, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                          child: _buildProfileStatCard('Talent Pool', '30+ Students', '3 Institutions'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildProfileStatCard('Target Hiring', targetRole, 'Drive Active'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildProfileStatCard('Cutoff Score', '65%', 'Readiness Min'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recruiter Details Card
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
                        Icon(Icons.business_center, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Recruitment Hub & Placement Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.domain, 'Corporate Company', company),
                    _buildDetailRow(Icons.school, 'Partner Colleges', collegeHub),
                    _buildDetailRow(Icons.mail_outline, 'Official Recruiter Email', recEmail),
                    _buildDetailRow(Icons.fact_check, 'Hiring Focus', 'Full Stack, Cloud & Data Analytics Campus Drive 2024-2025'),
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
                        content: Text('Logged out successfully from Recruiter Hub.'),
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
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
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
