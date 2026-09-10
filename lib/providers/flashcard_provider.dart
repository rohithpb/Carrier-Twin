import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/api_service.dart';

class FlashcardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<FlashcardModel> _allCards = [];
  List<FlashcardModel> _reviewQueue = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;

  String _selectedTopic = 'All';
  List<String> _availableTopics = ['All'];

  final Stopwatch _stopwatch = Stopwatch();
  ReviewResultModel? _lastReviewResult;
  FlashcardStatsModel? _stats;

  // Session Tracking
  int _sessionReviewedCount = 0;
  int _sessionCorrectCount = 0;
  int _sessionTotalTimeMs = 0;
  bool _isSessionFinished = false;

  // Getters
  List<FlashcardModel> get allCards => _allCards;
  List<FlashcardModel> get reviewQueue => _reviewQueue;
  int get currentIndex => _currentIndex;
  bool get isFlipped => _isFlipped;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  String get selectedTopic => _selectedTopic;
  List<String> get availableTopics => _availableTopics;
  ReviewResultModel? get lastReviewResult => _lastReviewResult;
  FlashcardStatsModel? get stats => _stats;

  int get sessionReviewedCount => _sessionReviewedCount;
  int get sessionCorrectCount => _sessionCorrectCount;
  int get sessionTotalTimeMs => _sessionTotalTimeMs;
  bool get isSessionFinished => _isSessionFinished;
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;

  FlashcardModel? get currentCard {
    if (_reviewQueue.isEmpty || _currentIndex >= _reviewQueue.length) {
      return null;
    }
    return _reviewQueue[_currentIndex];
  }

  int get dueCount => _allCards.where((c) => c.isDue).length;

  /// Load flashcards and deck statistics for a student
  Future<void> loadDeck(
    String studentId, {
    bool dueOnly = false,
    String? topic,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (topic != null) {
        _selectedTopic = topic;
      }

      // Fetch all cards first
      final rawCards = await _apiService.getFlashcards(studentId, dueOnly: false);
      _allCards = rawCards.map((c) => FlashcardModel.fromJson(c as Map<String, dynamic>)).toList();

      // If empty, trigger auto seed
      if (_allCards.isEmpty) {
        final seededRaw = await _apiService.seedFlashcards(studentId);
        _allCards = seededRaw.map((c) => FlashcardModel.fromJson(c as Map<String, dynamic>)).toList();
      }

      // Update topic list
      final topicSet = <String>{'All'};
      for (final card in _allCards) {
        if (card.tag.isNotEmpty) {
          topicSet.add(card.tag);
        }
      }
      _availableTopics = topicSet.toList();

      // Build active review queue
      _applyQueueFilter(dueOnly: dueOnly);

      // Load stats
      final rawStats = await _apiService.getFlashcardStats(studentId);
      if (rawStats != null) {
        _stats = FlashcardStatsModel.fromJson(rawStats);
      }

      _startCardTimer();
    } catch (e) {
      _errorMessage = 'Failed to load flashcard deck: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTopicFilter(String topic, {bool dueOnly = false}) {
    _selectedTopic = topic;
    _applyQueueFilter(dueOnly: dueOnly);
    _currentIndex = 0;
    _isFlipped = false;
    _lastReviewResult = null;
    _startCardTimer();
    notifyListeners();
  }

  void _applyQueueFilter({bool dueOnly = false}) {
    var filtered = _allCards;

    if (_selectedTopic != 'All') {
      filtered = filtered.where((c) => c.tag.toLowerCase() == _selectedTopic.toLowerCase()).toList();
    }

    if (dueOnly) {
      final dueList = filtered.where((c) => c.isDue).toList();
      _reviewQueue = dueList.isNotEmpty ? dueList : filtered;
    } else {
      _reviewQueue = List.from(filtered);
    }

    _isSessionFinished = _reviewQueue.isEmpty;
  }

  void _startCardTimer() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  /// Flip card between Front (Question) and Back (Answer)
  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  /// Submit an Anki review rating (1=Again, 2=Hard, 3=Good, 4=Easy)
  Future<void> submitReview(String studentId, int rating) async {
    final card = currentCard;
    if (card == null) return;

    _stopwatch.stop();
    final elapsedMs = _stopwatch.elapsedMilliseconds;

    try {
      final reviewData = await _apiService.reviewFlashcard(
        studentId,
        cardId: card.id,
        rating: rating,
        responseTimeMs: elapsedMs,
      );

      if (reviewData != null) {
        _lastReviewResult = ReviewResultModel.fromJson(reviewData);

        // Update card in memory list
        final updatedCard = _lastReviewResult!.flashcard;
        final allIdx = _allCards.indexWhere((c) => c.id == card.id);
        if (allIdx != -1) {
          _allCards[allIdx] = updatedCard;
        }

        // Track session metrics
        _sessionReviewedCount++;
        if (rating >= 3) {
          _sessionCorrectCount++;
        }
        _sessionTotalTimeMs += elapsedMs;

        // Anki re-queueing behavior: If rating is 1 (Again), re-insert card at end of session
        if (rating == 1) {
          _reviewQueue.add(updatedCard);
        }
      }

      // Advance queue
      if (_currentIndex < _reviewQueue.length - 1) {
        _currentIndex++;
        _isFlipped = false;
        _startCardTimer();
      } else {
        _isSessionFinished = true;
      }

      // Refresh stats
      final rawStats = await _apiService.getFlashcardStats(studentId);
      if (rawStats != null) {
        _stats = FlashcardStatsModel.fromJson(rawStats);
      }
    } catch (e) {
      _errorMessage = 'Error recording review: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Generate topic-specific flashcards via backend LLM
  Future<bool> generateTopicCards(
    String studentId, {
    required String topic,
    String? notes,
    int count = 5,
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawGenerated = await _apiService.generateFlashcards(
        studentId,
        topic: topic,
        notes: notes,
        count: count,
      );

      if (rawGenerated.isNotEmpty) {
        final newCards = rawGenerated.map((c) => FlashcardModel.fromJson(c as Map<String, dynamic>)).toList();
        _allCards.insertAll(0, newCards);

        // Update topics
        if (!_availableTopics.contains(topic)) {
          _availableTopics.add(topic);
        }

        // Switch to the newly generated topic deck
        setTopicFilter(topic);
        _isGenerating = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Topic card generation error: $e';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
    return false;
  }

  void resetSession() {
    _currentIndex = 0;
    _isFlipped = false;
    _sessionReviewedCount = 0;
    _sessionCorrectCount = 0;
    _sessionTotalTimeMs = 0;
    _isSessionFinished = false;
    _lastReviewResult = null;
    _applyQueueFilter();
    _startCardTimer();
    notifyListeners();
  }
}
