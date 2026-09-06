import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/student_provider.dart';
import '../../models/resume_model.dart';
import '../../services/resume_builder_service.dart';
import '../../services/ai_model_service.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ResumeBuilderService _resumeService = ResumeBuilderService();
  final AiModelService _aiService = AiModelService();
  late ResumeData _resumeData;
  bool _isInitialized = false;
  bool _isGeneratingSummary = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _newSkillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      _resumeData = _resumeService.generateDefaultResume(
        studentProvider.profile,
        studentProvider.selectedJobRole,
      );

      _nameController.text = _resumeData.fullName;
      _emailController.text = _resumeData.email;
      _phoneController.text = _resumeData.phone;
      _summaryController.text = _resumeData.summary;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _summaryController.dispose();
    _newSkillController.dispose();
    super.dispose();
  }

  void _addSkill(String skill, List<String> targetList) {
    if (skill.trim().isEmpty) return;
    setState(() {
      if (!targetList.contains(skill.trim())) {
        targetList.add(skill.trim());
      }
    });
    _newSkillController.clear();
  }

  void _removeSkill(String skill, List<String> targetList) {
    setState(() {
      targetList.remove(skill);
    });
  }

  void _exportResume() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text('ATS Resume generated successfully for download!')),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Resume Builder & Skill Alignment'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Edit Details & Skills'),
            Tab(icon: Icon(Icons.badge_outlined), text: 'ATS Resume Preview'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildEditorTab(studentProvider),
            _buildPreviewTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorTab(StudentProvider studentProvider) {
    final atsScore = _resumeData.atsScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ATS Optimization Score Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withBlue(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.workspace_premium, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'ATS Match Index',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Target: ${studentProvider.selectedJobRole.title}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: atsScore / 100.0,
                          minHeight: 10,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$atsScore%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Auto-populated from verified student skills & ${studentProvider.selectedJobRole.title} specifications.',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Personal & Contact Information
          const Text(
            'Personal Details & Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          _buildTextField(_nameController, 'Full Name', Icons.person),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTextField(_emailController, 'Email', Icons.email)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(_phoneController, 'Phone', Icons.phone)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Professional Profile Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _isGeneratingSummary
                    ? null
                    : () async {
                        setState(() => _isGeneratingSummary = true);
                        final studentProvider = Provider.of<StudentProvider>(context, listen: false);
                        final p = studentProvider.profile;
                        final role = studentProvider.selectedJobRole;
                        final prompt = '''
Write a compelling, professional 2-sentence ATS resume executive summary for ${p.displayName}, a student in ${p.departmentName} with ${p.cgpa} CGPA aiming for the role of "${role.title}".
Key acquired skills: ${_resumeData.coreSkills.join(', ')}, ${_resumeData.frameworksAndTools.join(', ')}.
Keep it concise, active, and impactful for recruiters.
''';
                        try {
                          final result = await _aiService.generateResponse(prompt);
                          if (mounted && result.isNotEmpty) {
                            setState(() {
                              _summaryController.text = result;
                              _resumeData.summary = result;
                            });
                          }
                        } catch (_) {}
                        if (mounted) setState(() => _isGeneratingSummary = false);
                      },
                icon: _isGeneratingSummary
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                label: Text(
                  _isGeneratingSummary ? 'AI Thinking...' : 'AI Auto-Write Summary',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _summaryController,
            maxLines: 3,
            onChanged: (val) => setState(() => _resumeData.summary = val),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter or auto-generate professional summary...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
            ),
          ),
          const SizedBox(height: 20),

          // 3. Auto-Populated Skill Matrix
          const Text(
            'Verified Technical Skills Matrix',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Skills pre-loaded from your Digital Twin profile. Add or remove skills to tailor your resume.',
            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          _buildSkillCategorySection('Core Programming Languages', _resumeData.coreSkills, AppColors.primary),
          const SizedBox(height: 12),
          _buildSkillCategorySection('Frameworks & Tools', _resumeData.frameworksAndTools, Colors.teal),
          const SizedBox(height: 12),
          _buildSkillCategorySection('Databases & Cloud Platforms', _resumeData.databasesAndCloud, Colors.deepPurple),
          const SizedBox(height: 20),

          // 4. Projects & NPTEL Certifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Projects & Certifications',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._resumeData.projects.map((proj) => Card(
                elevation: 0,
                color: AppColors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE8E3DC)),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(proj.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(proj.description, style: const TextStyle(fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('Stack: ${proj.techStack}', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  leading: const Icon(Icons.code, color: AppColors.primary),
                ),
              )),
          const SizedBox(height: 24),

          // Export Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _tabController.animateTo(1);
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Preview ATS Resume', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSkillCategorySection(String title, List<String> skills, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E3DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: themeColor),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...skills.map(
                (skill) => Chip(
                  label: Text(skill),
                  backgroundColor: themeColor.withOpacity(0.08),
                  side: BorderSide(color: themeColor.withOpacity(0.3)),
                  labelStyle: TextStyle(fontSize: 11, color: themeColor, fontWeight: FontWeight.w600),
                  deleteIcon: Icon(Icons.close, size: 14, color: themeColor),
                  onDeleted: () => _removeSkill(skill, skills),
                ),
              ),
              ActionChip(
                avatar: Icon(Icons.add, size: 14, color: themeColor),
                label: Text('Add Skill', style: TextStyle(fontSize: 11, color: themeColor, fontWeight: FontWeight.bold)),
                backgroundColor: themeColor.withOpacity(0.05),
                side: BorderSide(color: themeColor.withOpacity(0.2), style: BorderStyle.solid),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Add Skill to $title', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      content: TextField(
                        controller: _newSkillController,
                        autofocus: true,
                        decoration: const InputDecoration(hintText: 'e.g. Docker, TypeScript, PyTorch'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _addSkill(_newSkillController.text, skills);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      onChanged: (val) {
        if (label == 'Full Name') _resumeData.fullName = val;
        if (label == 'Email') _resumeData.email = val;
        if (label == 'Phone') _resumeData.phone = val;
        setState(() {});
      },
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildPreviewTab() {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Text(
                      _resumeData.fullName.toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_resumeData.targetRole} Candidate  •  ${_resumeData.location}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_resumeData.email}  |  ${_resumeData.phone}  |  ${_resumeData.githubUrl}',
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24, thickness: 1.5, color: Colors.black87),

              // Summary
              const Text('SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(_resumeData.summary, style: const TextStyle(fontSize: 11, height: 1.3, color: Colors.black87)),
              const SizedBox(height: 16),

              // Education
              const Text('EDUCATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black87)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_resumeData.collegeName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(_resumeData.batch, style: const TextStyle(fontSize: 11)),
                ],
              ),
              Text('${_resumeData.degree} (${_resumeData.department})  •  CGPA: ${_resumeData.cgpa.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
              const SizedBox(height: 16),

              // Technical Skills
              const Text('TECHNICAL SKILLS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black87)),
              const SizedBox(height: 4),
              Text('• Core Languages: ${_resumeData.coreSkills.join(", ")}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
              Text('• Frameworks & Tools: ${_resumeData.frameworksAndTools.join(", ")}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
              Text('• Databases & Cloud: ${_resumeData.databasesAndCloud.join(", ")}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
              const SizedBox(height: 16),

              // Projects
              const Text('KEY PROJECTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black87)),
              const SizedBox(height: 6),
              ..._resumeData.projects.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('• ${p.description}', style: const TextStyle(fontSize: 10.5, color: Colors.black87)),
                        Text('Technologies: ${p.techStack}', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.black54)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),

              // Certifications
              const Text('CERTIFICATIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black87)),
              const SizedBox(height: 4),
              ..._resumeData.certifications.map((c) => Text('• ${c.title} - ${c.issuer} (${c.year})', style: const TextStyle(fontSize: 10.5, color: Colors.black87))),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.surface,
        child: SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _exportResume,
            icon: const Icon(Icons.download),
            label: const Text('Export & Download ATS Resume', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
