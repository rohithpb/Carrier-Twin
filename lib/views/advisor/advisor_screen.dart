import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/student_provider.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ApiService _apiService = ApiService();
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
            'text': 'Hello ${profile.name}! I am your CareerTwin Academic & Career AI Advisor powered by NVIDIA NIM & Gemini. I have analyzed your ${profile.department} (Semester ${profile.currentSemesterNum}) digital twin profile & target role "${profile.careerPath}".\n\nAsk me any academic question, engineering concept, university syllabus topic, or exam preparation advice!'
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

    try {
      final reply = await _apiService.sendAdvisorChat(
        message: text,
        studentId: profile.uid.isNotEmpty ? profile.uid : 'student001',
        department: profile.departmentName,
        semester: profile.currentSemesterNum,
        targetRole: profile.careerPath,
      );
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
            'text': '⚠️ Connection error: $e',
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
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        title: const Row(
          children: [
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'NVIDIA NIM & Gemini Active',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Message List
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
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: isUser ? null : Border.all(color: const Color(0xFFE8E3DC)),
                        boxShadow: isUser
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                ),
                              ],
                      ),
                      child: SelectableText(
                        msg['text']!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isGenerating)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'CareerTwin AI is generating response via OpenAI / Gemini...',
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
                  _buildPromptChip('📚 Explain DBMS Normalization (1NF to BCNF)'),
                  _buildPromptChip('💻 Dijkstra’s Algorithm in Python'),
                  _buildPromptChip('🎯 Semester Exam Strategy & High-Yield Topics'),
                  _buildPromptChip('⚙️ TCP 3-Way Handshake Protocol'),
                  _buildPromptChip('📄 ATS Resume Format for Software Engineer'),
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
                        hintText: 'Ask any academic question, algorithm, or syllabus topic...',
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
        backgroundColor: AppColors.primaryFixed.withValues(alpha: 0.3),
        onPressed: () {
          _inputController.text = label;
          _sendMessage();
        },
      ),
    );
  }
}
