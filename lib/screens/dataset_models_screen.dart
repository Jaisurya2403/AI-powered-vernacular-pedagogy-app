import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/app_models.dart';
import '../engine/astar_translator.dart';
import '../theme/app_theme.dart';

class DatasetModelsScreen extends StatefulWidget {
  const DatasetModelsScreen({super.key});

  @override
  State<DatasetModelsScreen> createState() => _DatasetModelsScreenState();
}

class _DatasetModelsScreenState extends State<DatasetModelsScreen> {
  bool _isBenchmarking = false;
  List<Map<String, dynamic>> _benchmarkResults = [];

  void _runAStarBenchmark(AppState appState) {
    setState(() {
      _isBenchmarking = true;
      _benchmarkResults = [];
    });

    final testSentences = [
      "नमस्ते बच्चों, आप सब कैसे हैं?",
      "आज हम गणित सीखेंगे।",
      "अपनी किताब खोलो।",
      "एक से दस तक गिनती करो।",
      "पौधे को पानी और धूप चाहिए।",
      "शाबाश! बहुत बढ़िया।",
      "साफ पानी पीना स्वास्थ्य के लिए अच्छा है।",
      "सूरज पूरब दिशा में उगता है।",
    ];

    final targetLang = appState.targetLanguage;
    final dict = appState.datasetService.getDictionary(targetLang);
    final corpus = appState.datasetService.getParallelCorpus(targetLang);
    final phraseBank = appState.phraseBank.isNotEmpty ? appState.phraseBank : appState.datasetService.phraseBank;

    for (var sentence in testSentences) {
      final result = AStarTranslatorEngine.translate(
        inputText: sentence,
        targetLanguage: targetLang,
        wordDictionary: dict,
        parallelCorpus: corpus,
        phraseBank: phraseBank,
      );

      _benchmarkResults.add({
        'sentence': sentence,
        'translation': result.translatedText,
        'source': result.source.label,
        'latencyMs': result.latencyMs,
      });
    }

    setState(() {
      _isBenchmarking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isHindiUi = appState.uiLanguage == AppUiLanguage.hindi;

    return Container(
      color: const Color(0xFFF9F6F0),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hardware & Memory Profile Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.green.shade400, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x10800000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'SQLite Database & On-Device Profile: ACTIVE',
                        style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatChip('SQLite Engine', 'sqflite FFI'),
                      _buildStatChip('Target Latency', '< 3.0 sec'),
                      _buildStatChip('Current Speed', '< 40 ms'),
                      _buildStatChip('Offline Mode', 'ACTIVE ⚡'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Directory & SQLite Table Architecture Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: const [
                  BoxShadow(color: Color(0x10800000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dataset, color: AppTheme.deepCrimson, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        isHindiUi ? 'SQLite डेटाबेस और मॉडल संरचना' : 'SQLite Database Tables & Assets Architecture',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.borderSubtle, height: 20),
                  _buildFolderGuideItem(
                    folder: 'SQLite Table: users',
                    fileName: 'vernacular_pedagogy.db',
                    purpose: 'Stores registered teacher accounts, password SHA-256 hashes, and email OTP verification status',
                  ),
                  const SizedBox(height: 12),
                  _buildFolderGuideItem(
                    folder: 'SQLite Table: phrase_bank',
                    fileName: 'classroom_phrases.json (Seeded)',
                    purpose: 'Pre-translated classroom phrase bank table for O(1) instant translation lookup',
                  ),
                  const SizedBox(height: 12),
                  _buildFolderGuideItem(
                    folder: 'SQLite Table: word_dictionary',
                    fileName: 'hindi_santhali_dataset.json (Seeded)',
                    purpose: 'Dynamic word translation dictionary table powering the A* Search algorithm',
                  ),
                  const SizedBox(height: 12),
                  _buildFolderGuideItem(
                    folder: 'SQLite Table: session_logs',
                    fileName: 'vernacular_pedagogy.db',
                    purpose: 'Stores real-time continuous classroom speech translation history and notes',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. A* Search Algorithm Benchmark Suite
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: const [
                  BoxShadow(color: Color(0x10800000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isHindiUi ? 'A* एल्गोरिदम स्पीड परीक्षण' : 'A* Search Latency Benchmark',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      AnimatedPressButton(
                        onPressed: _isBenchmarking ? null : () => _runAStarBenchmark(appState),
                        isLoading: _isBenchmarking,
                        backgroundColor: AppTheme.deepCrimson,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.speed, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(isHindiUi ? 'परीक्षण चलाएं' : 'Run Benchmark', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_benchmarkResults.isEmpty)
                    Text(
                      isHindiUi
                          ? 'A* अनुवाद एल्गोरिदम की गति (<50ms) देखने के लिए "परीक्षण चलाएं" पर क्लिक करें।'
                          : 'Click "Run Benchmark" to test real-time A* search execution latency across sample sentences.',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _benchmarkResults.length,
                      itemBuilder: (context, index) {
                        final res = _benchmarkResults[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.lightCream,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    res['sentence'],
                                    style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${(res['latencyMs'] as double).toStringAsFixed(1)} ms',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${res['translation']} (${res['source']})',
                                style: const TextStyle(color: AppTheme.deepCrimson, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: AppTheme.deepCrimson, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildFolderGuideItem({required String folder, required String fileName, required String purpose}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.lightCream,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            folder,
            style: const TextStyle(color: AppTheme.deepCrimson, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text('Source: $fileName', style: const TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
        Text(purpose, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}
