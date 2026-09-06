import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/student_provider.dart';

class AcademicSetupDialog extends StatefulWidget {
  const AcademicSetupDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AcademicSetupDialog(),
    );
  }

  @override
  State<AcademicSetupDialog> createState() => _AcademicSetupDialogState();
}

class _AcademicSetupDialogState extends State<AcademicSetupDialog> {
  late int _selectedSemester;
  late String _selectedDept;
  late String _selectedTargetRole;
  late double _currentCgpa;
  late double _targetCgpa;
  late double _dailyHours;

  final List<String> _departments = [
    'B.Tech CSE',
    'B.Tech IT',
    'B.Tech ECE',
    'BCA Computer Applications',
    'B.Tech Mechanical',
  ];

  final List<String> _targetRoles = [
    'Data Analyst',
    'Cloud Engineer',
    'Full Stack Developer',
    'Machine Learning Engineer',
    'Cybersecurity Analyst',
  ];

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<StudentProvider>(context, listen: false).profile;
    _selectedSemester = profile.currentSemesterNum;
    _selectedDept = _departments.contains(profile.departmentName) ? profile.departmentName : _departments.first;
    _selectedTargetRole = _targetRoles.contains(profile.careerPath) ? profile.careerPath : _targetRoles.first;
    _currentCgpa = profile.currentGpa;
    _targetCgpa = profile.targetGpa;
    _dailyHours = profile.weeklyStudyHours / 7.0;
  }

  void _saveSetup() {
    final provider = Provider.of<StudentProvider>(context, listen: false);
    provider.updateAcademicSetup(
      currentSemesterNum: _selectedSemester,
      departmentName: _selectedDept,
      targetRole: _selectedTargetRole,
      currentGpa: _currentCgpa,
      targetGpa: _targetCgpa,
      dailyHours: _dailyHours,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Academic Plan updated for Semester $_selectedSemester ($_selectedDept). Day-by-Day schedule generated!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.school, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Academic & Semester Setup',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Text(
              'Configure your current semester, branch, and target career role to generate your personalized day-by-day study & workshop plan.',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Semester Selector
            const Text('Current Academic Semester', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(8, (i) {
                final sem = i + 1;
                final isSelected = _selectedSemester == sem;
                return ChoiceChip(
                  label: Text('Sem $sem'),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedSemester = sem),
                );
              }),
            ),
            const SizedBox(height: 14),

            // Department Dropdown
            const Text('Department / Branch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedDept,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.apartment, color: AppColors.outline),
                isDense: true,
              ),
              items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDept = val);
              },
            ),
            const SizedBox(height: 14),

            // Target Role Dropdown
            const Text('Target Career & Placement Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedTargetRole,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.work_outline, color: AppColors.outline),
                isDense: true,
              ),
              items: _targetRoles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedTargetRole = val);
              },
            ),
            const SizedBox(height: 14),

            // CGPA Sliders
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current CGPA: ${_currentCgpa.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Slider(
                        value: _currentCgpa,
                        min: 5.0,
                        max: 10.0,
                        divisions: 50,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _currentCgpa = v),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target CGPA: ${_targetCgpa.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Slider(
                        value: _targetCgpa,
                        min: 6.0,
                        max: 10.0,
                        divisions: 40,
                        activeColor: AppColors.tertiary,
                        onChanged: (v) => setState(() => _targetCgpa = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _saveSetup,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Save & Generate Day-by-Day Plan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
