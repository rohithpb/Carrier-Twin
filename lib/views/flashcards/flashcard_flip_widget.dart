import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/flashcard_model.dart';
import '../../theme/app_theme.dart';

/// Interactive 3D Card-Flipping Widget for Anki-style Spaced Repetition.
class FlashcardFlipWidget extends StatefulWidget {
  final FlashcardModel card;
  final bool isFlipped;
  final VoidCallback onFlip;
  final int elapsedMilliseconds;

  const FlashcardFlipWidget({
    super.key,
    required this.card,
    required this.isFlipped,
    required this.onFlip,
    this.elapsedMilliseconds = 0,
  });

  @override
  State<FlashcardFlipWidget> createState() => _FlashcardFlipWidgetState();
}

class _FlashcardFlipWidgetState extends State<FlashcardFlipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    if (widget.isFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant FlashcardFlipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(int ms) {
    final seconds = ms ~/ 1000;
    final decimal = (ms % 1000) ~/ 100;
    return '$seconds.${decimal}s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onFlip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final isBack = angle >= (math.pi / 2);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 3D Perspective
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildBackFace(),
                  )
                : _buildFrontFace(),
          );
        },
      ),
    );
  }

  Widget _buildFrontFace() {
    final tagColor = widget.card.tagColor;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 340, maxHeight: 440),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E3DC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Topic Tag & Status Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.label_outline, size: 14, color: tagColor),
                    const SizedBox(width: 6),
                    Text(
                      widget.card.tag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tagColor,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(widget.elapsedMilliseconds),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.card.isDue ? Colors.amber.withValues(alpha: 0.15) : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.card.dueTimeFormatted,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.card.isDue ? Colors.amber.shade900 : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Question Prompt
          Center(
            child: Column(
              children: [
                const Icon(Icons.psychology_outlined, size: 36, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  widget.card.front,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Flip Hint Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined, size: 16, color: AppColors.primary.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  'Tap card to reveal answer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackFace() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 340, maxHeight: 440),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.tertiary),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Answer & Explanation',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Interval: ${widget.card.interval}d • EF: ${widget.card.easeFactor.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE8E3DC)),
          const SizedBox(height: 16),

          // Answer Body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                widget.card.back,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                  height: 1.55,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Flip back affordance
          Center(
            child: Text(
              'Tap to flip back',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
