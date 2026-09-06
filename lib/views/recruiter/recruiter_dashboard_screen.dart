import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../models/student_profile.dart';

class RecruiterDashboardScreen extends StatefulWidget {
  const RecruiterDashboardScreen({super.key});

  @override
  State<RecruiterDashboardScreen> createState() => _RecruiterDashboardScreenState();
}

class _RecruiterDashboardScreenState extends State<RecruiterDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _allStudents = [];
  Map<String, dynamic>? _placementAnalytics;

  String _selectedCollege = 'ALL';
  final List<Map<String, String>> _colleges = [
    {'code': 'ALL', 'name': 'All Colleges'},
    {'code': 'JECC', 'name': 'Jyothi Engineering College (JECC)'},
    {'code': 'GECT', 'name': 'Govt Engineering College (GECT)'},
    {'code': 'MACE', 'name': 'Mar Athanasius College (MACE)'},
  ];

  String _selectedJobRole = 'Data Analyst';
  final List<String> _jobRoles = [
    'Data Analyst',
    'Cloud Engineer',
    'Full Stack Developer',
    'Machine Learning Engineer',
    'Cybersecurity Analyst',
    'Backend Developer',
    'Mobile App Developer',
    'DevOps Engineer'
  ];

  @override
  void initState() {
    super.initState();
    _loadCollegeData();
  }

  Future<void> _loadCollegeData() async {
    setState(() => _isLoading = true);
    final students = await _apiService.getStudents();
    final analytics = await _apiService.getPlacementAnalytics();

    if (mounted) {
      setState(() {
        _allStudents = students;
        _placementAnalytics = analytics;
        _isLoading = false;
      });
    }
  }

  void _inspectStudentProfile(Map<String, dynamic> s) {
    final name = s['name'] ?? 'Student';
    final dept = s['department'] ?? 'Computer Science';
    final year = s['current_year'] ?? 2;
    final readiness = s['career_readiness'] ?? 65;
    final skills = s['skill_levels'] as Map<String, dynamic>? ?? {};
    final activities = List<dynamic>.from(s['activities'] ?? []);
    final email = s['email'] ?? 'student@college.ac.in';
    final admissionNo = s['admission_no'] ?? s['username'] ?? '23CS101';
    final cgpa = s['cgpa'] ?? 8.42;

    String collegeName = 'Technology Institute';
    if (email.contains('jecc')) collegeName = 'Jyothi Engineering College (JECC)';
    else if (email.contains('gect')) collegeName = 'Govt Engineering College Thrissur (GECT)';
    else if (email.contains('mace')) collegeName = 'Mar Athanasius College (MACE)';

    final dummyProfile = StudentProfile(
      uid: s['id'] ?? 'student001',
      email: email,
      displayName: name,
      careerPath: s['target_role'] ?? 'Software Engineering',
      currentGpa: (cgpa as num).toDouble(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Student Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.secondaryContainer,
                    child: Text(
                      name.substring(0, 2).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSecondaryContainer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('$admissionNo • $dept', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        Text(collegeName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Readiness: $readiness%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onPrimaryFixed)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Academic Bento
              Row(
                children: [
                  Expanded(
                    child: _buildBentoCard('Verified CGPA', '$cgpa / 10', Icons.star, Colors.amber),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBentoCard('Active Backlogs', '0 Backlogs', Icons.verified_user, AppColors.tertiary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBentoCard('Current Year', 'Year $year', Icons.school, AppColors.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Download Official Placement CV PDF
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => PdfService.downloadCv(dummyProfile),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download Placement Single-Page CV (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 20),

              // Candidate Skill Levels
              const Text('Candidate Skills & Verification Levels:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.entries.map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE8E3DC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 6),
                      Text('${e.value}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // Activity Ledger
              const Text('Verified MOOCs, Workshops & Internships:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              if (activities.isEmpty)
                const Text('No activities logged yet.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant))
              else
                Column(
                  children: activities.map((act) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8E3DC)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(act['title'] ?? 'Activity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('${act["type"]} • ${act["date"] ?? "2026-09-05"}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryFixed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Score: ${act["score"] ?? 85}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onTertiaryFixed)),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = _placementAnalytics?['total_students'] ?? _allStudents.length;
    final jobReady = _placementAnalytics?['job_ready'] ?? 8;
    final developing = _placementAnalytics?['developing'] ?? 16;

    // Filter candidates matching target role AND college
    final matchedCandidates = _allStudents.where((s) {
      final email = (s['email'] ?? '').toString().toLowerCase();
      if (_selectedCollege == 'JECC' && !email.contains('jecc')) return false;
      if (_selectedCollege == 'GECT' && !email.contains('gect')) return false;
      if (_selectedCollege == 'MACE' && !email.contains('mace')) return false;

      final target = (s['target_role'] ?? '').toString();
      if (target.isEmpty) return true;
      return target.toLowerCase() == _selectedJobRole.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recruiter Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E3DC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.corporate_fare, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Ananya Sharma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('TechCorp Solutions • Lead Technical Recruiter', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryFixed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('RECRUITER HUB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onTertiaryFixed)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'College Talent Discovery Portal',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'View all student progress, academic readiness scores, and candidate skill matches across the institution.',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),

                    // Placement Stats Bento
                    Row(
                      children: [
                        Expanded(
                          child: _buildBentoCard('Total Talent Pool', '$totalStudents Students', Icons.groups, AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBentoCard('Job Ready Pool', '$jobReady Students', Icons.verified, AppColors.tertiary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBentoCard('In Development', '$developing Students', Icons.trending_up, AppColors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filter Candidates by College Institution
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E3DC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Text('Filter by College:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedCollege,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _colleges.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['code'],
                            child: Text(c['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCollege = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Filter by Target Job Role
              const Text('Filter Candidates by Target Job Role:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _jobRoles.map((role) {
                    final isSelected = _selectedJobRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(role),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _selectedJobRole = role),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // College Student List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Matched Student Candidates (${matchedCandidates.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('All College Data', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (matchedCandidates.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text('No students currently matching "$_selectedJobRole". Showing all college students below.')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matchedCandidates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final s = matchedCandidates[index];
                    final name = s['name'] ?? 'Student';
                    final dept = s['department'] ?? 'CS';
                    final year = s['current_year'] ?? 2;
                    final readiness = s['career_readiness'] ?? 65;
                    final targetRole = s['target_role'] ?? _selectedJobRole;
                    final skills = (s['skills'] as List<dynamic>?) ?? [];

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8E3DC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryFixed,
                                child: Text(
                                  name.substring(0, 2).toUpperCase(),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onPrimaryFixed),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text('$dept • Year $year • Role: $targetRole', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.tertiaryFixed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Readiness: $readiness%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onTertiaryFixed)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: skills.take(4).map((sk) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(sk.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                            )).toList(),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _inspectStudentProfile(s),
                              icon: const Icon(Icons.person_search, size: 16),
                              label: const Text('Inspect Full Student Progress & Verified MOOCs'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E3DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
