import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_model_service.dart';

class ApiKeySettingsDialog extends StatefulWidget {
  const ApiKeySettingsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ApiKeySettingsDialog(),
    );
  }

  @override
  State<ApiKeySettingsDialog> createState() => _ApiKeySettingsDialogState();
}

class _ApiKeySettingsDialogState extends State<ApiKeySettingsDialog> {
  late TextEditingController _geminiController;
  late TextEditingController _groqController;
  late TextEditingController _openAiController;
  late TextEditingController _openRouterController;

  String _selectedProvider = 'Gemini';
  final TextEditingController _newKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _geminiController = TextEditingController(text: AiModelService.geminiApiKeys.join('\n'));
    _groqController = TextEditingController(text: AiModelService.groqApiKeys.join('\n'));
    _openAiController = TextEditingController(text: AiModelService.openAiApiKeys.join('\n'));
    _openRouterController = TextEditingController(text: AiModelService.openRouterApiKeys.join('\n'));
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _groqController.dispose();
    _openAiController.dispose();
    _openRouterController.dispose();
    _newKeyController.dispose();
    super.dispose();
  }

  void _addKey() {
    final key = _newKeyController.text.trim();
    if (key.isEmpty) return;
    setState(() {
      AiModelService.addKey(_selectedProvider, key);
      _newKeyController.clear();
      _geminiController.text = AiModelService.geminiApiKeys.join('\n');
      _groqController.text = AiModelService.groqApiKeys.join('\n');
      _openAiController.text = AiModelService.openAiApiKeys.join('\n');
      _openRouterController.text = AiModelService.openRouterApiKeys.join('\n');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added new key to $_selectedProvider rotation pool.')),
    );
  }

  void _saveKeys() {
    final geminiList = _geminiController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final groqList = _groqController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final openAiList = _openAiController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final openRouterList = _openRouterController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    AiModelService.geminiApiKeys = geminiList;
    AiModelService.groqApiKeys = groqList;
    AiModelService.openAiApiKeys = openAiList;
    AiModelService.openRouterApiKeys = openRouterList;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI Model API Keys saved. Fast failover rotation active.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.vpn_key, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'AI API Key Manager',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Text(
              'Add multiple API keys across models. If one key runs out of credits or gets rate-limited, CareerTwin automatically switches to the next key.',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Add Quick Key Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E3DC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Add Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _selectedProvider,
                        items: ['Gemini', 'Groq', 'OpenAI', 'OpenRouter'].map((p) {
                          return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedProvider = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _newKeyController,
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            hintText: 'Paste API Key',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: _addKey,
                        child: const Text('Add', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Provider Pools
            _buildKeySection('Google Gemini Keys (1 key per line)', _geminiController, Icons.auto_awesome),
            const SizedBox(height: 12),
            _buildKeySection('Groq Llama 3 Keys (Free 30 RPM)', _groqController, Icons.bolt),
            const SizedBox(height: 12),
            _buildKeySection('OpenAI GPT-4o-mini Keys', _openAiController, Icons.psychology),
            const SizedBox(height: 12),
            _buildKeySection('OpenRouter Free Keys', _openRouterController, Icons.cloud),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _saveKeys,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save & Apply Key Rotation', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeySection(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: 2,
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            hintText: 'Enter API keys (one per line)',
            contentPadding: EdgeInsets.all(10),
          ),
        ),
      ],
    );
  }
}
