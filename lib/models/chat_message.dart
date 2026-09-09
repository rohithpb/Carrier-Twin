class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? source;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.source,
    this.isError = false,
  });

  factory ChatMessage.user(String text) {
    return ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.coach(String text, {String? source}) {
    return ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      source: source,
    );
  }

  factory ChatMessage.error(String text) {
    return ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );
  }

  Map<String, String> toHistoryMap() {
    return {
      'role': isUser ? 'user' : 'model',
      'content': text,
    };
  }
}
