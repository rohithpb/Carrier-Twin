import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../theme/app_theme.dart';

/// Modal dialog allowing students to generate AI-powered Anki cards for any topic.
class GenerateTopicDialog extends StatefulWidget {
  final String studentId;
  const GenerateTopicDialog({super.key, required this.studentId});

  static Future<bool?> show(BuildContext context, String studentId) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GenerateTopicDialog(studentId: studentId),
    );
  }

  @override
  State<GenerateTopicDialog> createState() => _GenerateTopicDialogState();
}

class _GenerateTopicDialogState extends State<GenerateTopicDialog> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  int _cardCount = 5;

  final List<String> _quickTopics = [
    'DBMS Normalization & BCNF',
    'Python Memory & GIL',
    'OS Virtual Memory & Paging',
    'Computer Networks TCP/IP',
    'B+ Tree Indexing & Trees',
    'SQL Joins & Window Functions',
    'Deadlock Coffman Conditions',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleGenerate() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a course topic.')),
      );
      return;
    }

    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    final success = await provider.generateTopicCards(
      widget.studentId,
      topic: topic,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      count: _cardCount,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.tertiary,
            content: Text('Generated active recall deck for "$topic"!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(provider.errorMessage ?? 'Failed to generate flashcards.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FlashcardProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate Topic Flashcards',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            'Active recall cards powered by LLM / Anki',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: provider.isGenerating ? null : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quick Pick Chips
              const Text(
                'Quick Pick Course Topics:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTopics.map((topic) {
                  final isSelected = _topicController.text == topic;
                  return ChoiceChip(
                    label: Text(topic, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryContainer.withValues(alpha: 0.2),
                    backgroundColor: AppColors.surfaceContainer,
                    onSelected: provider.isGenerating
                        ? null
                        : (selected) {
                            setState(() {
                              _topicController.text = selected ? topic : '';
                            });
                          },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Custom Topic Input
              TextField(
                controller: _topicController,
                enabled: !provider.isGenerating,
                decoration: InputDecoration(
                  labelText: 'Course Topic or Concept Name',
                  hintText: 'e.g. Relational Database Joins, Deadlock Avoidance',
                  prefixIcon: const Icon(Icons.school_outlined, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 14),

              // Optional Notes Input
              TextField(
                controller: _notesController,
                enabled: !provider.isGenerating,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Lecture Notes / Syllabus Snippet (Optional)',
                  hintText: 'Paste lecture notes or specific definitions to extract cards from...',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 16),

              // Card Count Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cards to Generate:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 3, label: Text('3')),
                      ButtonSegment(value: 5, label: Text('5')),
                      ButtonSegment(value: 8, label: Text('8')),
                    ],
                    selected: {_cardCount},
                    onSelectionChanged: provider.isGenerating
                        ? null
                        : (set) {
                            setState(() {
                              _cardCount = set.first;
                            });
                          },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.isGenerating ? null : _handleGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: provider.isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.flash_on, size: 20),
                  label: Text(
                    provider.isGenerating ? 'Synthesizing Topic Cards...' : 'Generate and Study Now',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
