import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/flashcard_model.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import 'flashcard_flip_widget.dart';
import 'generate_topic_dialog.dart';

/// Full-featured Anki-Style Spaced Repetition Study & Memory Enhancement Screen.
class FlashcardReviewScreen extends StatefulWidget {
  final String? initialTopic;
  const FlashcardReviewScreen({super.key, this.initialTopic});

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen> {
  Timer? _ticker;
  int _elapsedMs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final studentId = studentProvider.profile?.uid ?? 'student001';
      final flashcardProvider = Provider.of<FlashcardProvider>(context, listen: false);
      flashcardProvider.loadDeck(
        studentId,
        dueOnly: false,
        topic: widget.initialTopic,
      );
    });

    // Precision stopwatch ticker
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final provider = Provider.of<FlashcardProvider>(context, listen: false);
      if (mounted && !provider.isSessionFinished && provider.currentCard != null) {
        setState(() {
          _elapsedMs = provider.elapsedMilliseconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _showGenerateDialog() {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final studentId = studentProvider.profile?.uid ?? 'student001';
    GenerateTopicDialog.show(context, studentId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FlashcardProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final studentId = studentProvider.profile?.uid ?? 'student001';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Memory Retention & Spaced Repetition',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
            ),
            Text(
              'Anki-Android SM-2 & ML Scheduling',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant.withValues(alpha: 0.8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Generate Topic Cards',
            icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
            onPressed: _showGenerateDialog,
          ),
          IconButton(
            tooltip: 'Reset Deck Session',
            icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
            onPressed: () => provider.resetSession(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Topic Filter Selector
                  _buildTopicFilter(provider),

                  const SizedBox(height: 16),

                  // 2. Queue Progress & Due Tracker
                  _buildProgressHeader(provider),

                  const SizedBox(height: 20),

                  // 3. Main Area: Review Session or Completion
                  if (provider.isSessionFinished || provider.currentCard == null)
                    _buildCompletionCard(provider)
                  else ...[
                    // Interactive 3D Flip Card
                    FlashcardFlipWidget(
                      card: provider.currentCard!,
                      isFlipped: provider.isFlipped,
                      onFlip: () => provider.flipCard(),
                      elapsedMilliseconds: _elapsedMs,
                    ),

                    const SizedBox(height: 16),

                    // ML Insight Pill (if available from previous card)
                    if (provider.lastReviewResult != null)
                      _buildMlInsightBadge(provider.lastReviewResult!),

                    const SizedBox(height: 16),

                    // Anki Rating Response Bar (Shows when flipped, or reveals answer prompt)
                    if (provider.isFlipped)
                      _buildAnkiRatingBar(provider, studentId)
                    else
                      _buildRevealButton(provider),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTopicFilter(FlashcardProvider provider) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.availableTopics.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == provider.availableTopics.length) {
            return ActionChip(
              avatar: const Icon(Icons.add, size: 14, color: AppColors.primary),
              label: const Text('Add Topic', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              onPressed: _showGenerateDialog,
            );
          }

          final topic = provider.availableTopics[index];
          final isSelected = provider.selectedTopic == topic;

          return ChoiceChip(
            label: Text(topic, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
            selected: isSelected,
            selectedColor: AppColors.primaryContainer.withValues(alpha: 0.25),
            backgroundColor: AppColors.surfaceContainerLowest,
            side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE8E3DC)),
            onSelected: (_) => provider.setTopicFilter(topic),
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(FlashcardProvider provider) {
    final total = provider.reviewQueue.length;
    final current = provider.currentIndex + 1;
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DC)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.isSessionFinished ? 'Session Finished' : 'Card $current of $total',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${provider.dueCount} Due Today',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (provider.stats != null)
                    Text(
                      'Retention: ${(provider.stats!.retentionRate * 100).toInt()}%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tertiary),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealButton(FlashcardProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => provider.flipCard(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.flip_to_back, size: 20),
        label: const Text(
          'Show Answer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildAnkiRatingBar(FlashcardProvider provider, String studentId) {
    final card = provider.currentCard;
    final currentInt = card?.interval ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Rate your active recall performance:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 1. Again (Rating 1)
            Expanded(
              child: _buildRatingButton(
                title: 'Again',
                subtitle: '< 1d',
                color: const Color(0xFFD32F2F),
                onTap: () => provider.submitReview(studentId, 1),
              ),
            ),
            const SizedBox(width: 8),

            // 2. Hard (Rating 2)
            Expanded(
              child: _buildRatingButton(
                title: 'Hard',
                subtitle: '${(currentInt * 1.2).round().clamp(1, 45)}d',
                color: const Color(0xFFF57C00),
                onTap: () => provider.submitReview(studentId, 2),
              ),
            ),
            const SizedBox(width: 8),

            // 3. Good (Rating 3)
            Expanded(
              child: _buildRatingButton(
                title: 'Good',
                subtitle: '${(currentInt * (card?.easeFactor ?? 2.5)).round().clamp(1, 60)}d',
                color: const Color(0xFF2E7D32),
                onTap: () => provider.submitReview(studentId, 3),
              ),
            ),
            const SizedBox(width: 8),

            // 4. Easy (Rating 4)
            Expanded(
              child: _buildRatingButton(
                title: 'Easy',
                subtitle: '${(currentInt * (card?.easeFactor ?? 2.5) * 1.3).round().clamp(2, 90)}d',
                color: const Color(0xFF1976D2),
                onTap: () => provider.submitReview(studentId, 4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingButton({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMlInsightBadge(ReviewResultModel result) {
    final probPercent = (result.predictedRecallProbability * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, size: 18, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ML Recall Probability: $probPercent% • Interval: ${result.mlAdjustedInterval}d (${result.intervalAdjustmentReason})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(FlashcardProvider provider) {
    final reviewed = provider.sessionReviewedCount;
    final correct = provider.sessionCorrectCount;
    final accuracy = reviewed > 0 ? ((correct / reviewed) * 100).toInt() : 100;
    final avgSec = reviewed > 0 ? (provider.sessionTotalTimeMs / reviewed / 1000).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E3DC)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, size: 48, color: AppColors.tertiary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Review Session Complete!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'You completed your study queue for topic: "${provider.selectedTopic}"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // Session Stats Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetricTile('Reviewed', '$reviewed', Icons.layers_outlined, AppColors.primary),
              _buildMetricTile('Recall Acc', '$accuracy%', Icons.check_circle_outline, AppColors.tertiary),
              _buildMetricTile('Avg Speed', '${avgSec}s', Icons.speed_outlined, AppColors.secondary),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => provider.resetSession(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE8E3DC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Study Again', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showGenerateDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('New Topic', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
