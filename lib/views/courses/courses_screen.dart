import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final ApiService _apiService = ApiService();
  String _activeFilter = 'all';
  int _selectedSemester = 0; // 0 = All semesters, 1..8
  bool _isUploading = false;
  String _uploadStatus = '';
  List<dynamic> _opportunities = [];
  bool _isLoading = true;
  int _currentReadiness = 68;

  @override
  void initState() {
    super.initState();
    _fetchOpportunities();
    _fetchStudentReadiness();
  }

  Future<void> _fetchOpportunities() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getOpportunities();
    if (mounted) {
      setState(() {
        _opportunities = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStudentReadiness() async {
    final twin = await _apiService.getDigitalTwin('student001');
    if (twin != null && mounted) {
      setState(() {
        _currentReadiness = twin['career_readiness'] ?? 68;
      });
    }
  }

  Future<void> _completeOpportunity(Map<String, dynamic> opp) async {
    final title = opp['title'] ?? 'Completed Course';
    final type = opp['type'] ?? 'MOOC';
    final skills = List<String>.from(opp['required_skills'] ?? []);

    final res = await _apiService.addActivity('student001', {
      'title': title,
      'type': type,
      'score': 85,
      'skills_covered': skills,
      'date': DateTime.now().toString().split(' ')[0],
    });

    if (res != null && mounted) {
      final newScore = res['updated_career_readiness'] ?? _currentReadiness;
      setState(() {
        _currentReadiness = newScore;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Completed "$title"!\n+15 Skill boost in ${skills.join(", ")}. Readiness: $newScore%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _simulateCertificateUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg'],
      );

      if (result != null && result.files.isNotEmpty) {
        final fileName = result.files.first.name;
        setState(() {
          _isUploading = true;
          _uploadStatus = 'Selected $fileName. Extracting NPTEL Digital Signature...';
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _uploadStatus = 'Verifying Course Score & Faculty Mapping...';
            });
          }
        });

        Future.delayed(const Duration(seconds: 2), () async {
          if (mounted) {
            setState(() {
              _uploadStatus = 'Approved! +15 Skill Boost & +3 Credits Added!';
            });
            await _completeOpportunity({
              'title': 'NPTEL Verified Certification ($fileName)',
              'type': 'CERTIFICATION',
              'required_skills': ['Python', 'SQL'],
            });
          }
        });
      }
    } catch (_) {
      setState(() {
        _isUploading = true;
        _uploadStatus = 'Extracting NPTEL Digital Signature...';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter opportunities
    final filteredOpps = _opportunities.where((o) {
      if (_selectedSemester > 0) {
        final targetSem = o['target_semester'] ?? 0;
        if (targetSem != 0 && targetSem != _selectedSemester) return false;
      }
      if (_activeFilter != 'all') {
        final type = (o['type'] ?? '').toString().toLowerCase();
        if (_activeFilter == 'mooc' && type != 'mooc') return false;
        if (_activeFilter == 'internship' && type != 'internship') return false;
        if (_activeFilter == 'cert' && type != 'certification') return false;
        if (_activeFilter == 'workshop' && type != 'workshop' && type != 'hackathon') return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.school, size: 14, color: AppColors.onPrimaryFixed),
                              SizedBox(width: 4),
                              Text(
                                'ACADEMIC DIGITAL TWIN LEDGER',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onPrimaryFixed),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryFixed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Readiness: $_currentReadiness%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onTertiaryFixed),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Semester 1–8 Progression Roadmap',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete curated courses, certifications, and internships to earn skills, clear skill gaps, and boost career readiness.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),

                    // Quick Counters
                    Row(
                      children: [
                        Expanded(
                          child: _buildBentoCard(
                            icon: Icons.stars,
                            iconColor: AppColors.primary,
                            value: '$_currentReadiness / 100',
                            label: 'Readiness Score',
                            progress: _currentReadiness / 100.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBentoCard(
                            icon: Icons.menu_book,
                            iconColor: AppColors.secondary,
                            value: '${_opportunities.length} Courses',
                            label: 'Available',
                            progress: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBentoCard(
                            icon: Icons.verified,
                            iconColor: AppColors.tertiary,
                            value: 'Sem 1–8',
                            label: 'Mapped',
                            progress: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Semester Filter Chips
              const Text('Select Semester:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSemesterChip(0, 'All Semesters'),
                    for (int sem = 1; sem <= 8; sem++) _buildSemesterChip(sem, 'Sem $sem'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Type Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Types'),
                    _buildFilterChip('mooc', 'NPTEL / MOOCs'),
                    _buildFilterChip('internship', 'Internships'),
                    _buildFilterChip('cert', 'Certifications'),
                    _buildFilterChip('workshop', 'Workshops & Hackathons'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Opportunity List
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (filteredOpps.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('No courses or internships found for this filter.')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredOpps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final opp = filteredOpps[index];
                    return _buildOpportunityCard(opp);
                  },
                ),

              const SizedBox(height: 20),

              // Certificate Upload Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E3DC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Expanded(
                          child: Text(
                            'Transfer College Credits / Upload PDF',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('OCR Verified', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _simulateCertificateUpload,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outlineVariant, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text('Tap to upload NPTEL / Coursera Certificate PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Automated credit transfer & skill boost', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const CircularProgressIndicator(strokeWidth: 2.5),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _uploadStatus,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.tertiary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpportunityCard(Map<String, dynamic> opp) {
    final title = opp['title'] ?? '';
    final org = opp['organization'] ?? '';
    final desc = opp['description'] ?? '';
    final type = opp['type'] ?? 'MOOC';
    final targetSem = opp['target_semester'] ?? 0;
    final skills = List<String>.from(opp['required_skills'] ?? []);

    Color badgeColor = AppColors.primary;
    if (type == 'INTERNSHIP') badgeColor = Colors.orange.shade700;
    if (type == 'CERTIFICATION') badgeColor = Colors.purple.shade700;
    if (type == 'HACKATHON') badgeColor = Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
              if (targetSem > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Semester $targetSem',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(org, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 10),

          // Skill tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+ $s',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSecondaryContainer),
              ),
            )).toList(),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _completeOpportunity(opp),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Complete & Log to Digital Twin'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceContainerHigh,
            color: iconColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterChip(int sem, String label) {
    final isSelected = _selectedSemester == sem;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.secondary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _selectedSemester = sem),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _activeFilter = key),
      ),
    );
  }
}
