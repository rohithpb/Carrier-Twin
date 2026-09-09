import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class CareerCoachProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastSource;
  Map<String, dynamic>? _studentContext;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastSource => _lastSource;
  Map<String, dynamic>? get studentContext => _studentContext;

  /// Initialize conversation with personalized greeting if empty
  void initDefaultGreeting(String studentName, String targetRole) {
    if (_messages.isNotEmpty) return;
    final firstName = studentName.trim().isNotEmpty ? studentName.split(' ').first : 'Student';
    _messages.add(
      ChatMessage.coach(
        'Hello $firstName! 👋 I am your CareerTwin AI Career Coach.\n\n'
        'I am connected directly to your Educational Digital Twin, tracking your academics, skill proficiencies, and readiness score toward becoming a **$targetRole**.\n\n'
        'Ask me anything about bridging your skill gaps, high-impact project ideas, or boosting your campus placement readiness!',
        source: 'coach',
      ),
    );
    notifyListeners();
  }

  /// Send a message to the FastAPI GenAI Career Coach endpoint
  Future<void> sendMessage(String text, String studentId) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    // 1. Append user message
    _messages.add(ChatMessage.user(trimmed));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 2. Prepare history payload (last 6 turns to keep context optimal)
    final history = _messages
        .where((m) => !m.isError)
        .take(_messages.length - 1) // exclude just added user message
        .toList();
    final recentHistory = history.length > 6
        ? history.sublist(history.length - 6)
        : history;
    final historyMaps = recentHistory.map((m) => m.toHistoryMap()).toList();

    try {
      final res = await _apiService.sendChatMessage(
        studentId: studentId,
        message: trimmed,
        chatHistory: historyMaps,
      );

      if (res != null && res['response'] != null) {
        final responseText = res['response'] as String;
        final source = res['source'] as String? ?? 'gemini';
        _lastSource = source;
        if (res['student_context_summary'] != null) {
          _studentContext = res['student_context_summary'] as Map<String, dynamic>;
        }

        _messages.add(ChatMessage.coach(responseText, source: source));
      } else {
        // Friendly fallback message if server communication failed
        _messages.add(
          ChatMessage.error(
            'Unable to reach the Career Coach server at this moment. Please ensure the backend is running on port 8000.',
          ),
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      _messages.add(
        ChatMessage.error(
          'An error occurred while connecting to the career coach: $e',
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset the conversation
  void clearChat(String studentName, String targetRole) {
    _messages.clear();
    _errorMessage = null;
    _lastSource = null;
    initDefaultGreeting(studentName, targetRole);
  }
}
