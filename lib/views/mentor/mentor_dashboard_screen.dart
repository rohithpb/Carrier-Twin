import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class MentorDashboardScreen extends StatefulWidget {
  const MentorDashboardScreen({super.key});

  @override
  State<MentorDashboardScreen> createState() => _MentorDashboardScreenState();
}

class _MentorDashboardScreenState extends State<MentorDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _mentorData;
  Map<String, dynamic>? _mentorAnalytics;

  List<dynamic> _allStudents = [];
  List<String> _assignedIds = [
    'student001',
    'student004',
    'student006',
    'student011',
    'student016',
    'student022'
  ];

  String _selectedCollege = 'JECC';
  final List<Map<String, String>> _colleges = [
    {'code': 'JECC', 'name': 'Jyothi Engineering College (JECC)'},
    {'code': 'GECT', 'name': 'Govt Engineering College (GECT)'},
    {'code': 'MACE', 'name': 'Mar Athanasius College (MACE)'},
    {'code': 'ALL', 'name': 'All Partner Colleges'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMentorData();
  }

  Future<void> _loadMentorData() async {
    setState(() => _isLoading = true);
    final analytics = await _apiService.getMentorAnalytics('mentor001');
    final allStudents = await _apiService.getStudents();

    if (mounted) {
      setState(() {
        _mentorData = {
          'name': 'Dr. Priya Nair',
          'department': 'Computer Science & Engineering',
          'designation': 'Associate Professor & HOD',
          'assigned_class': 'CS 2023-2027 (Year 2 - S4)',
          'college': 'Jyothi Engineering College (JECC)',
        };
        _mentorAnalytics = analytics;
        _allStudents = allStudents;
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredMentees {
    return _allStudents.where((s) {
      final isAssigned = _assignedIds.contains(s['id']);
      if (!isAssigned) return false;
      if (_selectedCollege == 'ALL') return true;
      final email = (s['email'] ?? '').toString().toLowerCase();
      if (_selectedCollege == 'JECC' && email.contains('jecc')) return true;
      if (_selectedCollege == 'GECT' && email.contains('gect')) return true;
      if (_selectedCollege == 'MACE' && email.contains('mace')) return true;
      return true;
    }).toList();
  }

  void _assignStudentDialog() {
    final unassigned = _allStudents.where((s) => !_assignedIds.contains(s['id'])).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Row(
          children: const [
            Icon(Icons.person_add, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Assign New Student Mentee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: unassigned.isEmpty
              ? const Text('All available students are currently assigned.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: unassigned.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final student = unassigned[index];
                    final name = student['name'] ?? 'Student';
                    final dept = student['department'] ?? 'Department';
                    final email = student['email'] ?? '';
                    final id = student['id'];

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('$dept • $email', style: const TextStyle(fontSize: 11)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                        onPressed: () {
                          setState(() {
                            _assignedIds.add(id);
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Assigned $name to your mentorship roster.')),
                          );
                        },
                        child: const Text('Assign', style: TextStyle(fontSize: 11)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMenteeDetails(Map<String, dynamic> mentee) {
    final name = mentee['name'] ?? 'Student';
    int readiness = mentee['career_readiness'] ?? 68;
    final status = mentee['status'] ?? 'Developing';
    final skills = mentee['skill_levels'] as Map<String, dynamic>? ?? {};
    final skillGap = List<String>.from(mentee['skill_gap'] ?? []);
    final activities = List<dynamic>.from(mentee['activities'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        name.substring(0, 2).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('${mentee["department"]} • ${mentee["email"] ?? ""}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Readiness: $readiness%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onPrimaryFixed),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Faculty Endorsement Action Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E3DC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.verified_user, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Faculty Readiness Evaluation & Endorsement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setModalState(() {
                                  readiness = (readiness + 5).clamp(0, 100);
                                  mentee['career_readiness'] = readiness;
                                });
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Endorsed $name! Career readiness updated to $readiness%.')),
                                );
                              },
                              icon: const Icon(Icons.thumb_up, size: 16),
                              label: const Text('Endorse & Boost (+5%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              setModalState(() {
                                readiness = (readiness - 5).clamp(0, 100);
                                mentee['career_readiness'] = readiness;
                              });
                              setState(() {});
                            },
                            icon: const Icon(Icons.remove_circle_outline, size: 16),
                            label: const Text('-5%', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Academic Stats
                Row(
                  children: [
                    _buildStatTile('CGPA', '${mentee["cgpa"] ?? 8.0}', Icons.star, Colors.amber),
                    const SizedBox(width: 10),
                    _buildStatTile('Status', status, Icons.trending_up, AppColors.primary),
                    const SizedBox(width: 10),
                    _buildStatTile('Target Role', '${mentee["target_role"] ?? "Developer"}', Icons.work, AppColors.secondary),
                  ],
                ),
                const SizedBox(height: 20),

                // Skill Levels
                const Text('Earned Skills Proficiency (Verified):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${e.value}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onPrimaryFixed)),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),

                // Skill Gap
                if (skillGap.isNotEmpty) ...[
                  const Text('Missing Skill Gap (Action Needed):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: skillGap.map((sg) => Chip(
                      avatar: const Icon(Icons.warning, size: 14, color: Colors.white),
                      backgroundColor: Colors.red.shade700,
                      label: Text(sg, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Completed Activities
                const Text('Academic Activity & MOOC Ledger:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E3DC)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mentees = _filteredMentees;
    final avgReadiness = mentees.isNotEmpty
        ? (mentees.fold<double>(0, (sum, m) => sum + (m['career_readiness'] ?? 68)) / mentees.length).toStringAsFixed(1)
        : '78.3';
    final totalMentees = mentees.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mentor Profile Header Card
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
                          radius: 24,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.school, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _mentorData?['name'] ?? 'Dr. Priya Nair',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                '${_mentorData?["designation"]} • ${_mentorData?["department"]}',
                                style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('FACULTY MENTOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onPrimaryFixed)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Assigned Class Batch:', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                              Text(_mentorData?['assigned_class'] ?? 'CS Year 2', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Batch Avg Readiness:', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                              Text('$avgReadiness%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filter Mentees by Institution Dropdown Row
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
                    const Text('College Filter:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

              // Mentee Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assigned Student Mentees ($totalMentees)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _assignStudentDialog,
                    icon: const Icon(Icons.person_add, size: 14),
                    label: const Text('Assign Mentee', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (mentees.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text('No assigned mentees found for $_selectedCollege. Tap "Assign Mentee" to add students.'),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mentees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final m = mentees[index];
                    final name = m['name'] ?? 'Student';
                    final readiness = m['career_readiness'] ?? 68;
                    final cgpa = m['cgpa'] ?? 8.0;
                    final targetRole = m['target_role'] ?? 'Software Engineer';
                    final skillGap = List<String>.from(m['skill_gap'] ?? []);

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
                                backgroundColor: AppColors.primaryContainer.withOpacity(0.4),
                                child: Text(
                                  name.substring(0, 2).toUpperCase(),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text('Target: $targetRole • CGPA: $cgpa', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Score: $readiness%',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onPrimaryFixed),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Skill Gap Alert
                          if (skillGap.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Skill Gap: ${skillGap.join(", ")}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showMenteeDetails(m),
                              icon: const Icon(Icons.visibility_outlined, size: 14),
                              label: const Text('View Full Digital Twin & Endorse Readiness'),
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
}
