import 'package:flutter/material.dart';

/// Represents a spaced repetition flashcard based on Anki-Android / SM-2 schemas.
class FlashcardModel {
  final String id;
  final String studentId;
  final String front;
  final String back;
  final int interval; // in days
  final double easeFactor; // starting 2.5
  final int repetitions;
  final String dueDate; // ISO string
  final String tag; // Topic or skill node
  final int lastResponseTimeMs;
  final String createdAt;

  const FlashcardModel({
    required this.id,
    required this.studentId,
    required this.front,
    required this.back,
    this.interval = 1,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    required this.dueDate,
    this.tag = 'General',
    this.lastResponseTimeMs = 0,
    required this.createdAt,
  });

  bool get isDue {
    try {
      final due = DateTime.parse(dueDate);
      return DateTime.now().toUtc().isAfter(due);
    } catch (_) {
      return true;
    }
  }

  String get dueTimeFormatted {
    try {
      final due = DateTime.parse(dueDate);
      final diff = due.difference(DateTime.now().toUtc());
      if (diff.isNegative) {
        return 'Due Now';
      } else if (diff.inDays > 0) {
        return 'In ${diff.inDays}d';
      } else if (diff.inHours > 0) {
        return 'In ${diff.inHours}h';
      } else {
        return 'In ${diff.inMinutes}m';
      }
    } catch (_) {
      return 'Due';
    }
  }

  Color get tagColor {
    final t = tag.toLowerCase();
    if (t.contains('dbms') || t.contains('sql') || t.contains('database')) {
      return const Color(0xFF1E88E5);
    } else if (t.contains('python') || t.contains('code') || t.contains('algorithm')) {
      return const Color(0xFF2E7D32);
    } else if (t.contains('os') || t.contains('operating')) {
      return const Color(0xFFD84315);
    } else if (t.contains('network') || t.contains('tcp')) {
      return const Color(0xFF6A1B9A);
    }
    return const Color(0xFF9E3D1E);
  }

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      front: json['front']?.toString() ?? '',
      back: json['back']?.toString() ?? '',
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      dueDate: json['dueDate']?.toString() ?? DateTime.now().toIso8601String(),
      tag: json['tag']?.toString() ?? 'General',
      lastResponseTimeMs: (json['lastResponseTimeMs'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'front': front,
      'back': back,
      'interval': interval,
      'easeFactor': easeFactor,
      'repetitions': repetitions,
      'dueDate': dueDate,
      'tag': tag,
      'lastResponseTimeMs': lastResponseTimeMs,
      'created_at': createdAt,
    };
  }
}

class ReviewResultModel {
  final FlashcardModel flashcard;
  final int sm2Interval;
  final int mlAdjustedInterval;
  final double predictedRecallProbability;
  final String intervalAdjustmentReason;
  final double easeFactorChange;

  const ReviewResultModel({
    required this.flashcard,
    required this.sm2Interval,
    required this.mlAdjustedInterval,
    required this.predictedRecallProbability,
    required this.intervalAdjustmentReason,
    required this.easeFactorChange,
  });

  factory ReviewResultModel.fromJson(Map<String, dynamic> json) {
    return ReviewResultModel(
      flashcard: FlashcardModel.fromJson(json['flashcard'] as Map<String, dynamic>),
      sm2Interval: (json['sm2_interval'] as num?)?.toInt() ?? 1,
      mlAdjustedInterval: (json['ml_adjusted_interval'] as num?)?.toInt() ?? 1,
      predictedRecallProbability: (json['predicted_recall_probability'] as num?)?.toDouble() ?? 0.85,
      intervalAdjustmentReason: json['interval_adjustment_reason']?.toString() ?? '',
      easeFactorChange: (json['ease_factor_change'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FlashcardStatsModel {
  final int totalCards;
  final int dueCards;
  final double retentionRate;
  final int averageResponseTimeMs;
  final List<String> topics;
  final Map<String, int> cardsByTopic;

  const FlashcardStatsModel({
    required this.totalCards,
    required this.dueCards,
    required this.retentionRate,
    required this.averageResponseTimeMs,
    required this.topics,
    required this.cardsByTopic,
  });

  factory FlashcardStatsModel.fromJson(Map<String, dynamic> json) {
    return FlashcardStatsModel(
      totalCards: (json['total_cards'] as num?)?.toInt() ?? 0,
      dueCards: (json['due_cards'] as num?)?.toInt() ?? 0,
      retentionRate: (json['retention_rate'] as num?)?.toDouble() ?? 0.85,
      averageResponseTimeMs: (json['average_response_time_ms'] as num?)?.toInt() ?? 3000,
      topics: (json['topics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      cardsByTopic: (json['cards_by_topic'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
    );
  }
}
