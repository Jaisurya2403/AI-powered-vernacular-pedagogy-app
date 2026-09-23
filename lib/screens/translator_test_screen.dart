import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../translation/hindi_santali_translator.dart';
import '../translation/translator_manager.dart';

class TranslatorTestScreen extends StatefulWidget {
  const TranslatorTestScreen({super.key});

  @override
  State<TranslatorTestScreen> createState() => _TranslatorTestScreenState();
}

class _TranslatorTestScreenState extends State<TranslatorTestScreen> {
  final TextEditingController _inputController = TextEditingController(text: 'आज हम गणित पढ़ेंगे');
  TranslationResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _runTranslation();
  }

  void _runTranslation() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final translator = TranslatorManager().translator;
    final res = translator.translate(text);
    setState(() {
      _lastResult = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryYellow,
      appBar: AppBar(
        title: const Text('Step 2: 3-Tier A* Translation Engine Diagnostic'),
        backgroundColor: AppTheme.deepCrimson,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x1F800000), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Input Hindi Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter Hindi sentence to translate...',
                    ),
                    onChanged: (_) => _runTranslation(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _inputController.text = 'आज हम गणित पढ़ेंगे';
                          _runTranslation();
                        },
                        child: const Text('Test 1: Verbatim Exact'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _inputController.text = 'आज  हम  गणित   पढ़ेंगे! ।';
                          _runTranslation();
                        },
                        child: const Text('Test 2: Fuzzy Punctuation'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _inputController.text = 'नमस्ते बच्चों आज हम गणित पढ़ेंगे';
                          _runTranslation();
                        },
                        child: const Text('Test 3: A* Composed'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _inputController.text = 'नमस्ते रोबोट आज गणित पढ़ेंगे';
                          _runTranslation();
                        },
                        child: const Text('Test 4: Unmatched Word [робот]'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_lastResult != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.deepCrimson,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Santhali Output (Ol Chiki):',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryYellow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tier: ${_lastResult!.method.toUpperCase()}',
                            style: const TextStyle(color: AppTheme.deepCrimson, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _lastResult!.santaliText.isEmpty ? '[No result]' : _lastResult!.santaliText,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Latency: ${_lastResult!.latencyMs.toStringAsFixed(2)} ms (< 20 ms budget)',
                          style: const TextStyle(color: AppTheme.primaryYellow, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        if (_lastResult!.unmatchedHindiWords.isNotEmpty)
                          Text(
                            'Unmatched: ${_lastResult!.unmatchedHindiWords.join(", ")}',
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
