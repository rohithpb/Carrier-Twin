import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_model_service.dart';
import '../../providers/student_provider.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final AiModelService _aiService = AiModelService();
  bool _isGenerating = false;

  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final profile = studentProvider.profile;
      if (_messages.isEmpty) {
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': 'Hello ${profile.name}! I am your CareerTwin AI Advisor. I have analyzed your ${profile.department} (Semester ${profile.currentSemesterNum}) profile & target role "${profile.careerPath}". How can I help boost your campus readiness today?'
          });
        });
      }
    });
  }

  void _sendMessage() async {
    if (_inputController.text.trim().isEmpty || _isGenerating) return;
    final text = _inputController.text.trim();
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final profile = studentProvider.profile;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _inputController.clear();
      _isGenerating = true;
    });

    final contextualPrompt = '''
You are a warm, perceptive, highly natural Personal Career Assistant & Mentor for university engineering students.
Speak in a natural, conversational human tone (like an experienced senior engineer and mentor sitting next to the student).
Do NOT sound like a generic robotic AI, do NOT say "As an AI language model". Speak with empathy, direct actionable advice, and natural human enthusiasm!

Student Digital Twin Context:
- Name: ${profile.displayName}
- Institution & Dept: ${profile.departmentName} (Semester ${profile.currentSemesterNum})
- Current CGPA: ${profile.cgpa.toStringAsFixed(2)}
- Target Role: ${profile.careerPath}
- Completed Skills: ${profile.completedSkillIds.join(', ')}

Student Question: "$text"

Give a personal, highly specific, encouraging answer in natural human conversational language.
''';

    try {
      final reply = await _aiService.generateResponse(contextualPrompt);
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': reply});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': 'Got it ${profile.displayName}! I am updating your CareerTwin Pulse score based on "$text". You can check your progress in the Dashboard anytime!'
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withOpacity(0.9),
        title: Row(
          children: const [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryFixed,
              child: Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
            ),
            SizedBox(width: 8),
            Text('CareerTwin AI Advisor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tertiaryFixed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('V3.2 Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onTertiaryFixed)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: isUser ? null : Border.all(color: const Color(0xFFE8E3DC)),
                        boxShadow: isUser
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                ),
                              ],
                      ),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isGenerating)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Advisor is generating response...',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.primary),
                    ),
                  ],
                ),
              ),

            // Quick Prompt Chips
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPromptChip('🎯 Daily Semester Strategy'),
                  _buildPromptChip('💼 Mock Interview Prep'),
                  _buildPromptChip('📄 ATS Resume Audit'),
                  _buildPromptChip('📜 NPTEL Credit Advice'),
                ],
              ),
            ),

            // Input Field
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border(top: BorderSide(color: Color(0xFFE8E3DC))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Ask CareerTwin AI anything...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryFixed.withOpacity(0.3),
        onPressed: () {
          _inputController.text = label;
          _sendMessage();
        },
      ),
    );
  }
}
