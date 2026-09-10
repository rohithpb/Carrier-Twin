import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_model_service.dart';
import '../../providers/student_provider.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final AiModelService _aiService = AiModelService();
  bool _isGenerating = false;

  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final profile = studentProvider.profile;
      if (_messages.isEmpty) {
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': 'Hello ${profile.name}! I am your CareerTwin Academic & Career AI Advisor. I have analyzed your ${profile.department} (Semester ${profile.currentSemesterNum}) profile & target role "${profile.careerPath}".\n\nAsk me any academic question, engineering concept, syllabus topic, or exam preparation advice!'
          });
        });
      }
    });
  }

  void _showApiKeyDialog() {
    final TextEditingController keyController = TextEditingController(
      text: AiModelService.primaryApiKey,
    );
    String selectedProvider = AiModelService.hasAnyKey
        ? AiModelService.activeProviderName
        : 'Gemini';
    bool obscureText = true;
    bool isTesting = false;
    String? testResult;
    bool testSuccess = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryFixed,
                    child: Icon(Icons.vpn_key_rounded, size: 18, color: AppColors.primary),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Academic AI API Key',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paste your API key below. Academic and career queries will be processed directly through this key.',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    // Provider Selector
                    Row(
                      children: [
                        const Text('AI Provider:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE8E3DC)),
                          ),
                          child: DropdownButton<String>(
                            value: selectedProvider,
                            underline: const SizedBox(),
                            isDense: true,
                            items: const [
                              DropdownMenuItem(value: 'Gemini', child: Text('Google Gemini (Free & Fast)', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Groq', child: Text('Groq Cloud (Llama 3.1)', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'OpenAI', child: Text('OpenAI (GPT-4o mini)', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'OpenRouter', child: Text('OpenRouter', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedProvider = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Key Input Field
                    TextField(
                      controller: keyController,
                      obscureText: obscureText,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      onChanged: (val) {
                        final detected = AiModelService.detectProvider(val);
                        if (detected != selectedProvider && val.trim().isNotEmpty) {
                          setDialogState(() => selectedProvider = detected);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        hintText: selectedProvider == 'Gemini' ? 'AIzaSy...' : 'Paste key here',
                        filled: true,
                        fillColor: AppColors.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E3DC))),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, size: 18),
                              onPressed: () => setDialogState(() => obscureText = !obscureText),
                            ),
                            IconButton(
                              tooltip: 'Paste from clipboard',
                              icon: const Icon(Icons.content_paste_rounded, size: 18),
                              onPressed: () async {
                                final data = await Clipboard.getData(Clipboard.kTextPlain);
                                if (data?.text != null && data!.text!.trim().isNotEmpty) {
                                  keyController.text = data.text!.trim();
                                  final detected = AiModelService.detectProvider(keyController.text);
                                  setDialogState(() => selectedProvider = detected);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Test result feedback
                    if (isTesting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Verifying API key...', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      )
                    else if (testResult != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: testSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: testSuccess ? Colors.green : Colors.red),
                        ),
                        child: Row(
                          children: [
                            Icon(testSuccess ? Icons.check_circle : Icons.error_outline, size: 16, color: testSuccess ? Colors.green : Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                testResult!,
                                style: TextStyle(fontSize: 11, color: testSuccess ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Free Key Link
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('https://aistudio.google.com/app/apikey');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_new, size: 13, color: AppColors.primary),
                        label: const Text(
                          'Get a Free Google Gemini API Key ↗',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (AiModelService.hasAnyKey)
                  TextButton(
                    onPressed: () {
                      AiModelService.clearKeys();
                      setState(() {});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API Key removed.')),
                      );
                    },
                    child: const Text('Remove Key', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                OutlinedButton(
                  onPressed: isTesting
                      ? null
                      : () async {
                          final key = keyController.text.trim();
                          if (key.isEmpty) {
                            setDialogState(() {
                              testResult = 'Please paste an API key first.';
                              testSuccess = false;
                            });
                            return;
                          }
                          setDialogState(() {
                            isTesting = true;
                            testResult = null;
                          });
                          try {
                            final res = await _aiService.testKey(selectedProvider, key);
                            setDialogState(() {
                              isTesting = false;
                              testResult = 'Success: $res';
                              testSuccess = true;
                            });
                          } catch (e) {
                            setDialogState(() {
                              isTesting = false;
                              testResult = 'Failed: ${e.toString().replaceFirst("Exception: ", "")}';
                              testSuccess = false;
                            });
                          }
                        },
                  child: const Text('Test Key', style: TextStyle(fontSize: 12)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final key = keyController.text.trim();
                    if (key.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please paste a valid API key.')),
                      );
                      return;
                    }
                    AiModelService.setKey(key, provider: selectedProvider);
                    setState(() {});
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ ${selectedProvider.toUpperCase()} API key connected successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Save & Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _sendMessage() async {
    if (_inputController.text.trim().isEmpty || _isGenerating) return;
    final text = _inputController.text.trim();
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final profile = studentProvider.profile;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _inputController.clear();
      _isGenerating = true;
    });

    if (!AiModelService.hasAnyKey) {
      setState(() {
        _isGenerating = false;
        _messages.add({
          'sender': 'ai',
          'text': '🔑 Please connect your API key first to unlock live answers for academic questions!\n\nClick the "🔑 Set API Key" button in the top bar to paste your Google Gemini (free) or Groq/OpenAI key.',
        });
      });
      _showApiKeyDialog();
      return;
    }

    final contextualPrompt = '''
You are the CareerTwin Academic AI Advisor & University Engineering Tutor.
You specialize in undergraduate and graduate engineering academics (${profile.departmentName}), university syllabus topics, textbook concepts, algorithms, code walkthroughs, exam preparation, and career progression.

Student Profile:
- Name: ${profile.displayName}
- Department: ${profile.departmentName} (Semester ${profile.currentSemesterNum})
- Current CGPA: ${profile.cgpa.toStringAsFixed(2)}
- Target Role: ${profile.careerPath}
- Verified Skills: ${profile.completedSkillIds.join(', ')}

Student Academic Question:
"$text"

Instructions for your response:
1. Academic In-Depth Answers: Answer the question accurately and educationally. Break down complex engineering and programming concepts step-by-step.
2. Code & Examples: Include clean code snippets, diagrams (ASCII/formatted), or mathematical formulas where relevant.
3. Exam & Viva Tips: Point out typical university exam questions, key definitions to remember, or interview talking points related to this topic.
4. Formatting: Use neat headings, bullet points, and bold terms for high readability.
''';

    try {
      final reply = await _aiService.generateResponse(contextualPrompt);
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': reply});
        });
      }
    } catch (e) {
      if (mounted) {
        final cleanError = e.toString().replaceFirst("Exception: ", "");
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': '⚠️ AI API Error: $cleanError\n\nPlease verify that your API key is valid and active by clicking the "API Key" button in the top bar.'
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = AiModelService.hasAnyKey;
    final provider = AiModelService.activeProviderName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryFixed,
              child: Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
            ),
            SizedBox(width: 8),
            Text('CareerTwin AI Advisor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          InkWell(
            onTap: _showApiKeyDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hasKey ? Colors.green.withValues(alpha: 0.12) : AppColors.primaryFixed.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasKey ? Colors.green : AppColors.primary,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasKey ? Icons.check_circle_rounded : Icons.vpn_key_rounded,
                    size: 14,
                    color: hasKey ? Colors.green[800] : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasKey ? '$provider Key Active' : '🔑 Set API Key',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasKey ? Colors.green[900] : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // API Key Prompt Banner if not connected
            if (!hasKey)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key_rounded, size: 20, color: Color(0xFFEA580C)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI API Key Required for Live Answers',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Paste your free Google Gemini API key to ask academic questions.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFC2410C)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _showApiKeyDialog,
                      child: const Text('Paste Key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Message List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: isUser ? null : Border.all(color: const Color(0xFFE8E3DC)),
                        boxShadow: isUser
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                ),
                              ],
                      ),
                      child: SelectableText(
                        msg['text']!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isGenerating)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CareerTwin AI is generating response using $provider...',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.primary),
                    ),
                  ],
                ),
              ),

            // Quick Prompt Chips
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPromptChip('📚 Explain DBMS Normalization (1NF to BCNF)'),
                  _buildPromptChip('💻 Dijkstra’s Algorithm in Python'),
                  _buildPromptChip('🎯 Semester Exam Strategy & Important Topics'),
                  _buildPromptChip('⚙️ TCP 3-Way Handshake Explained'),
                  _buildPromptChip('📄 ATS Resume Format for Software Engineer'),
                ],
              ),
            ),

            // Input Field
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border(top: BorderSide(color: Color(0xFFE8E3DC))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Ask any academic question, algorithm, or syllabus topic...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryFixed.withValues(alpha: 0.3),
        onPressed: () {
          _inputController.text = label;
          _sendMessage();
        },
      ),
    );
  }
}

