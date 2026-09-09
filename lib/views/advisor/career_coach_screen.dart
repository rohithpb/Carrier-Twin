import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/career_coach_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/chat_message.dart';

class CareerCoachScreen extends StatefulWidget {
  const CareerCoachScreen({super.key});

  @override
  State<CareerCoachScreen> createState() => _CareerCoachScreenState();
}

class _CareerCoachScreenState extends State<CareerCoachScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickSuggestions = [
    '💡 How can I improve my Cloud & DevOps skills?',
    '🎯 What high-impact projects should I build?',
    '📈 How do I raise my 7-Pillar Readiness score?',
    '⚡ What are my primary skill gaps right now?',
    '💼 How do I prepare for campus placement interviews?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final coachProvider = Provider.of<CareerCoachProvider>(context, listen: false);
      final profile = studentProvider.profile;
      coachProvider.initDefaultGreeting(profile.name, profile.careerPath);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? presetText]) {
    final text = presetText ?? _inputController.text.trim();
    if (text.isEmpty) return;

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final coachProvider = Provider.of<CareerCoachProvider>(context, listen: false);

    if (presetText == null) {
      _inputController.clear();
    }

    coachProvider.sendMessage(text, studentProvider.profile.uid);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final coachProvider = Provider.of<CareerCoachProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final profile = studentProvider.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF9E4B28)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CareerTwin AI Coach',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.1),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Digital Twin Synced (${profile.careerPath})',
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.onSurfaceVariant),
            tooltip: 'Reset Conversation',
            onPressed: () {
              coachProvider.clearChat(profile.name, profile.careerPath);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick Suggestion Chips Carousel
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: Color(0xFFE8E3DC))),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickSuggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _quickSuggestions[index];
                  return ActionChip(
                    label: Text(
                      prompt,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: AppColors.surfaceContainerLowest,
                    side: const BorderSide(color: Color(0xFFDED8D0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: coachProvider.isLoading ? null : () => _sendMessage(prompt),
                  );
                },
              ),
            ),

            // Messages View
            Expanded(
              child: coachProvider.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: coachProvider.messages.length + (coachProvider.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == coachProvider.messages.length) {
                          return _buildLoadingBubble();
                        }
                        final message = coachProvider.messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
            ),

            // Input Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFDED8D0)),
                      ),
                      child: TextField(
                        controller: _inputController,
                        textInputAction: TextInputAction.send,
                        maxLines: 4,
                        minLines: 1,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Ask your career coach anything...',
                          hintStyle: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: coachProvider.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: coachProvider.isLoading ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Coach Response Bubble
    final isError = message.isError;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade100 : const Color(0xFFF0EBE3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError ? Icons.error_outline : Icons.auto_awesome,
              size: 16,
              color: isError ? Colors.red.shade800 : AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? Colors.red.shade50 : AppColors.surfaceContainerLowest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: isError ? Colors.red.shade200 : const Color(0xFFE8E3DC),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      color: isError ? Colors.red.shade900 : const Color(0xFF2D2A26),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  if (message.source != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          message.source == 'gemini' ? '⚡ Powered by Gemini' : '🛡️ Rule-Based Heuristic',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFF0EBE3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E3DC)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                SizedBox(width: 8),
                Text(
                  'Coach is analyzing your digital twin...',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
