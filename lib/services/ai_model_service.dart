import 'dart:convert';
import 'package:http/http.dart' as http;

/// Multi-Model AI Service with Automatic Key Rotation & Multi-Tier Failover
class AiModelService {
  // Configured Key Lists for each AI model provider
  static List<String> nvidiaApiKeys = [];
  static List<String> geminiApiKeys = [];
  static List<String> groqApiKeys = [];
  static List<String> openAiApiKeys = [];
  static List<String> openRouterApiKeys = [];

  static bool get hasAnyKey =>
      nvidiaApiKeys.isNotEmpty ||
      geminiApiKeys.isNotEmpty ||
      groqApiKeys.isNotEmpty ||
      openAiApiKeys.isNotEmpty ||
      openRouterApiKeys.isNotEmpty;

  static String get activeProviderName {
    if (nvidiaApiKeys.isNotEmpty) return 'NVIDIA NIM';
    if (geminiApiKeys.isNotEmpty) return 'Gemini';
    if (groqApiKeys.isNotEmpty) return 'Groq';
    if (openAiApiKeys.isNotEmpty) return 'OpenAI';
    if (openRouterApiKeys.isNotEmpty) return 'OpenRouter';
    return 'None';
  }

  static String get primaryApiKey {
    if (nvidiaApiKeys.isNotEmpty) return nvidiaApiKeys.first;
    if (geminiApiKeys.isNotEmpty) return geminiApiKeys.first;
    if (groqApiKeys.isNotEmpty) return groqApiKeys.first;
    if (openAiApiKeys.isNotEmpty) return openAiApiKeys.first;
    if (openRouterApiKeys.isNotEmpty) return openRouterApiKeys.first;
    return '';
  }

  /// Auto-detect the AI provider from key prefix
  static String detectProvider(String key) {
    final clean = key.trim();
    if (clean.startsWith('nvapi-')) return 'NVIDIA';
    if (clean.startsWith('AQ.') || clean.startsWith('AIzaSy')) return 'Gemini';
    if (clean.startsWith('gsk_')) return 'Groq';
    if (clean.startsWith('sk-or-')) return 'OpenRouter';
    if (clean.startsWith('sk-')) return 'OpenAI';
    return 'Gemini';
  }

  /// Sets the primary key, replacing previous keys for a clean setup
  static void setKey(String key, {String provider = 'auto'}) {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) return;
    final resolvedProvider = provider == 'auto' ? detectProvider(cleanKey) : provider;
    clearKeys();
    addKey(resolvedProvider, cleanKey);
  }

  /// Clear all stored keys
  static void clearKeys() {
    nvidiaApiKeys.clear();
    geminiApiKeys.clear();
    groqApiKeys.clear();
    openAiApiKeys.clear();
    openRouterApiKeys.clear();
  }

  // Helper getters/setters for legacy single key calls
  static String get nvidiaApiKey => nvidiaApiKeys.isNotEmpty ? nvidiaApiKeys.first : "";
  static set nvidiaApiKey(String key) {
    if (key.trim().isNotEmpty && !nvidiaApiKeys.contains(key.trim())) {
      nvidiaApiKeys.insert(0, key.trim());
    }
  }

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
      case 'nvidia':
      case 'nvidianim':
        if (!nvidiaApiKeys.contains(cleanKey)) nvidiaApiKeys.add(cleanKey);
        break;
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

  /// Test an API key with a fast ping
  Future<String> testKey(String provider, String apiKey) async {
    final clean = apiKey.trim();
    if (clean.isEmpty) throw Exception('API key cannot be empty.');
    switch (provider.toLowerCase()) {
      case 'nvidia':
      case 'nvidianim':
        return await _callNvidiaWithKey('Say "API Key is valid!" in 5 words.', clean);
      case 'gemini':
        return await _callGeminiWithKey('Say "API Key is valid!" in 5 words.', clean);
      case 'groq':
        return await _callGroqWithKey('Say "API Key is valid!" in 5 words.', clean);
      case 'openai':
        return await _callOpenAiWithKey('Say "API Key is valid!" in 5 words.', clean);
      case 'openrouter':
        return await _callOpenRouterWithKey('Say "API Key is valid!" in 5 words.', clean);
      default:
        throw Exception('Unknown provider: $provider');
    }
  }

  /// Generate AI response with key rotation failover:
  /// Rotates through NVIDIA -> Gemini -> Groq -> OpenAI -> OpenRouter keys
  Future<String> generateResponse(String prompt) async {
    String? lastError;

    // Tier 1: NVIDIA NIM Cascade
    for (int i = 0; i < nvidiaApiKeys.length; i++) {
      final key = nvidiaApiKeys[i].trim();
      if (key.isEmpty) continue;
      try {
        final reply = await _callNvidiaWithKey(prompt, key);
        return reply;
      } catch (e) {
        lastError = 'NVIDIA error: $e';
        print("NVIDIA Key #${i + 1} error: $e");
      }
    }

    // Tier 2: Gemini Keys Cascade
    for (int i = 0; i < geminiApiKeys.length; i++) {
      final key = geminiApiKeys[i].trim();
      if (key.isEmpty) continue;
      try {
        final reply = await _callGeminiWithKey(prompt, key);
        return reply;
      } catch (e) {
        lastError = 'Gemini error: $e';
        print("Gemini Key #${i + 1} error: $e");
      }
    }

    // Tier 3: Groq Keys Cascade
    for (int i = 0; i < groqApiKeys.length; i++) {
      final key = groqApiKeys[i].trim();
      if (key.isEmpty) continue;
      try {
        final reply = await _callGroqWithKey(prompt, key);
        return reply;
      } catch (e) {
        lastError = 'Groq error: $e';
        print("Groq Key #${i + 1} error: $e");
      }
    }

    // Tier 4: OpenAI Keys Cascade
    for (int i = 0; i < openAiApiKeys.length; i++) {
      final key = openAiApiKeys[i].trim();
      if (key.isEmpty) continue;
      try {
        final reply = await _callOpenAiWithKey(prompt, key);
        return reply;
      } catch (e) {
        lastError = 'OpenAI error: $e';
        print("OpenAI Key #${i + 1} error: $e");
      }
    }

    // Tier 5: OpenRouter Keys Cascade
    for (int i = 0; i < openRouterApiKeys.length; i++) {
      final key = openRouterApiKeys[i].trim();
      if (key.isEmpty) continue;
      try {
        final reply = await _callOpenRouterWithKey(prompt, key);
        return reply;
      } catch (e) {
        lastError = 'OpenRouter error: $e';
        print("OpenRouter Key #${i + 1} error: $e");
      }
    }

    // If the user configured an API key and it failed, inform them of the real error!
    if (hasAnyKey) {
      throw Exception(lastError ?? 'API key call failed. Please verify your key.');
    }

    // Smart Offline Rule-Based Fallback if no keys were added
    return _generateSmartOfflineFallback(prompt);
  }

  /// 0. NVIDIA NIM REST API Call
  Future<String> _callNvidiaWithKey(String prompt, String apiKey) async {
    final models = [
      'meta/llama-3.2-11b-vision-instruct',
      'meta/llama-3.2-90b-vision-instruct',
      'mistralai/mistral-large-2-instruct',
    ];
    final url = Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions');
    String? lastError;

    for (final model in models) {
      try {
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': 'You are CareerTwin AI Advisor.'},
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.3,
            'max_tokens': 1500,
          }),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['choices']?[0]?['message']?['content'];
          if (text != null && text.isNotEmpty) return text;
        } else {
          lastError = 'NVIDIA HTTP ${response.statusCode}: ${response.body}';
        }
      } catch (e) {
        lastError = e.toString();
        continue;
      }
    }
    throw Exception(lastError ?? 'NVIDIA NIM call failed.');
  }

  /// 1. Google Gemini Single Key API Call (Supports multiple model endpoints)
  Future<String> _callGeminiWithKey(String prompt, String apiKey) async {
    final models = ['gemini-2.5-flash', 'gemini-flash-latest', 'gemini-2.0-flash', 'gemini-1.5-flash', 'gemini-1.5-pro'];
    String? lastError;

    for (final model in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null && text.isNotEmpty) return text;
        } else if (response.statusCode == 404) {
          lastError = 'Model $model not found (404)';
          continue;
        } else {
          try {
            final jsonErr = jsonDecode(response.body);
            final msg = jsonErr['error']?['message'] ?? response.body;
            throw Exception('Gemini ($model): $msg');
          } catch (pe) {
            if (pe is Exception && pe.toString().contains('Gemini (')) rethrow;
            throw Exception('Gemini HTTP ${response.statusCode}: ${response.body}');
          }
        }
      } catch (e) {
        lastError = e.toString();
        if (e.toString().contains('404')) continue;
        rethrow;
      }
    }
    throw Exception(lastError ?? 'Gemini API call failed.');
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
