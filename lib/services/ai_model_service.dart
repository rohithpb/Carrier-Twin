import 'dart:convert';
import 'package:http/http.dart' as http;

/// Multi-Model AI Service with Automatic Key Rotation & Multi-Tier Failover
class AiModelService {
  // Configured Key Lists for each AI model provider
  static List<String> geminiApiKeys = [];
  static List<String> groqApiKeys = [];
  static List<String> openAiApiKeys = [];
  static List<String> openRouterApiKeys = [];


  // Helper getters/setters for legacy single key calls
  static String get geminiApiKey => geminiApiKeys.isNotEmpty ? geminiApiKeys.first : "";
  static set geminiApiKey(String key) {
    if (key.trim().isNotEmpty && !geminiApiKeys.contains(key.trim())) {
      geminiApiKeys.insert(0, key.trim());
    }
  }

  static String get groqApiKey => groqApiKeys.isNotEmpty ? groqApiKeys.first : "";
  static set groqApiKey(String key) {
    if (key.trim().isNotEmpty && !groqApiKeys.contains(key.trim())) {
      groqApiKeys.insert(0, key.trim());
    }
  }

  static String get openAiApiKey => openAiApiKeys.isNotEmpty ? openAiApiKeys.first : "";
  static set openAiApiKey(String key) {
    if (key.trim().isNotEmpty && !openAiApiKeys.contains(key.trim())) {
      openAiApiKeys.insert(0, key.trim());
    }
  }

  static String get openRouterApiKey => openRouterApiKeys.isNotEmpty ? openRouterApiKeys.first : "";
  static set openRouterApiKey(String key) {
    if (key.trim().isNotEmpty && !openRouterApiKeys.contains(key.trim())) {
      openRouterApiKeys.insert(0, key.trim());
    }
  }

  /// Add a key to a specific provider
  static void addKey(String provider, String key) {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) return;
    switch (provider.toLowerCase()) {
      case 'gemini':
        if (!geminiApiKeys.contains(cleanKey)) geminiApiKeys.add(cleanKey);
        break;
      case 'groq':
        if (!groqApiKeys.contains(cleanKey)) groqApiKeys.add(cleanKey);
        break;
      case 'openai':
        if (!openAiApiKeys.contains(cleanKey)) openAiApiKeys.add(cleanKey);
        break;
      case 'openrouter':
        if (!openRouterApiKeys.contains(cleanKey)) openRouterApiKeys.add(cleanKey);
        break;
    }
  }

  /// Generate AI response with key rotation failover:
  /// Rotates through Gemini keys -> Groq keys -> OpenAI keys -> OpenRouter keys -> Smart Offline Fallback
  Future<String> generateResponse(String prompt) async {
    // Tier 1: Gemini Keys Cascade
    for (int i = 0; i < geminiApiKeys.length; i++) {
      final key = geminiApiKeys[i].trim();
      if (key.isEmpty) continue;
      try {
        final reply = await _callGeminiWithKey(prompt, key);
        return reply;
      } catch (e) {
        print("Gemini Key #${i + 1} exhausted/failed: $e. Rotating to next key...");
      }
    }

    // Tier 2: Groq Keys Cascade
    for (int i = 0; i < groqApiKeys.length; i++) {
      final key = groqApiKeys[i].trim();
      if (key.isEmpty) continue;
      try {
        final reply = await _callGroqWithKey(prompt, key);
        return reply;
      } catch (e) {
        print("Groq Key #${i + 1} exhausted/failed: $e. Rotating to next key...");
      }
    }

    // Tier 3: OpenAI Keys Cascade
    for (int i = 0; i < openAiApiKeys.length; i++) {
      final key = openAiApiKeys[i].trim();
      if (key.isEmpty) continue;
      try {
        final reply = await _callOpenAiWithKey(prompt, key);
        return reply;
      } catch (e) {
        print("OpenAI Key #${i + 1} exhausted/failed: $e. Rotating to next key...");
      }
    }

    // Tier 4: OpenRouter Keys Cascade
    for (int i = 0; i < openRouterApiKeys.length; i++) {
      final key = openRouterApiKeys[i].trim();
      if (key.isEmpty) continue;
      try {
        final reply = await _callOpenRouterWithKey(prompt, key);
        return reply;
      } catch (e) {
        print("OpenRouter Key #${i + 1} exhausted/failed: $e. Rotating...");
      }
    }

    // Smart Offline Rule-Based Fallback if all API keys are exhausted or offline
    return _generateSmartOfflineFallback(prompt);
  }

  /// 1. Google Gemini Single Key API Call
  Future<String> _callGeminiWithKey(String prompt, String apiKey) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': 'You are CareerTwin AI Advisor. Be encouraging, concise, and helpful for academic & placement queries.\nUser query: $prompt'}
            ]
          }
        ]
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text != null && text.isNotEmpty) return text;
    }
    throw Exception('Gemini HTTP ${response.statusCode}: ${response.body}');
  }

  /// 2. Groq Cloud API Call
  Future<String> _callGroqWithKey(String prompt, String apiKey) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.1-70b-versatile',
        'messages': [
          {'role': 'system', 'content': 'You are CareerTwin AI Advisor.'},
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    }
    throw Exception('Groq HTTP ${response.statusCode}');
  }

  /// 3. OpenAI GPT-4o-mini API Call
  Future<String> _callOpenAiWithKey(String prompt, String apiKey) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': 'You are CareerTwin AI Advisor.'},
          {'role': 'user', 'content': prompt}
        ],
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    }
    throw Exception('OpenAI HTTP ${response.statusCode}');
  }

  /// 4. OpenRouter Free Models Call
  Future<String> _callOpenRouterWithKey(String prompt, String apiKey) async {
    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'nvidia/nemotron-3.5-lightning:free',
        'messages': [
          {'role': 'system', 'content': 'You are CareerTwin AI Advisor.'},
          {'role': 'user', 'content': prompt}
        ],
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    }
    throw Exception('OpenRouter HTTP ${response.statusCode}');
  }

  /// Fallback rule-based advisor when offline or all API limits are temporarily hit
  String _generateSmartOfflineFallback(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('certification') || lower.contains('nptel') || lower.contains('course')) {
      return "For S4 Computer Science, we recommend completing 1 NPTEL certification (e.g. IIT Madras Python for Data Science or Database Systems) to earn +3 university minor credits and boost your campus placement shortlist chance to 88%.";
    } else if (lower.contains('resume') || lower.contains('cv') || lower.contains('ats')) {
      return "To optimize your placement resume: 1) Keep it strictly 1 page. 2) List your verified CGPA (8.42). 3) Include your GitHub link with project repos. 4) Highlight verified tech skills (Python, SQL, C++).";
    } else if (lower.contains('interview') || lower.contains('tcs') || lower.contains('company')) {
      return "For TCS Digital & Cognizant GenC Next: Focus on Data Structures (Trees & Graphs), DBMS normalization SQL queries, and prepare 2 strong project walkthroughs.";
    }
    return "Thank you for asking! Focus on maintaining your CGPA above 7.50, completing 1 NPTEL certification, and solving 2 coding problems daily to stay eligible for all 24 visiting campus placement drives.";
  }
}
