import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/notes_generator_service.dart';
import '../theme/app_theme.dart';

class BilingualNotesScreen extends StatefulWidget {
  const BilingualNotesScreen({super.key});

  @override
  State<BilingualNotesScreen> createState() => _BilingualNotesScreenState();
}

class _BilingualNotesScreenState extends State<BilingualNotesScreen> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  bool _isExporting = false;
  String? _exportedFilePath;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _topicController.text = appState.currentLessonTopic;
    _teacherController.text = appState.teacherName;
  }

  @override
  void dispose() {
    _topicController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isHindiUi = appState.uiLanguage == AppUiLanguage.hindi;
    final targetLang = appState.targetLanguage;

    final docPreviewText = NotesGeneratorService.generateBilingualDocContent(
      sessionLogs: appState.sessionLogs,
      targetLanguage: targetLang,
      lessonTopic: _topicController.text,
      teacherName: _teacherController.text,
      teacherSchool: appState.teacherSchool,
      teacherDesignation: appState.teacherDesignation,
      teacherEmail: appState.teacherEmail,
    );

    return Container(
      color: const Color(0xFFF9F6F0),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Color(0x15800000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description, color: AppTheme.deepCrimson, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isHindiUi ? 'निपुण भारत - द्विभाषी नोट्स वर्कर' : 'NIPUN Bharat - Bilingual Notes Generator',
                          style: const TextStyle(color: AppTheme.deepCrimson, fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isHindiUi
                        ? 'कक्षा संवाद से स्वतः संरचित एमएस वर्ड (.docx) वर्कशीट उत्पन्न करें।'
                        : 'Automatically converts classroom conversation logs into structured Word (.docx) worksheets.',
                    style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lesson Metadata Form Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: const [
                  BoxShadow(color: Color(0x10800000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _topicController,
                    style: const TextStyle(color: AppTheme.textDark),
                    decoration: InputDecoration(
                      labelText: isHindiUi ? 'पाठ विषय (Lesson Topic)' : 'Lesson Topic',
                      prefixIcon: const Icon(Icons.menu_book, color: AppTheme.deepCrimson),
                    ),
                    onChanged: (val) {
                      appState.updateLessonTopic(val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _teacherController,
                    style: const TextStyle(color: AppTheme.textDark),
                    decoration: InputDecoration(
                      labelText: isHindiUi ? 'शिक्षक का नाम (Teacher Name)' : 'Teacher Name',
                      prefixIcon: const Icon(Icons.person, color: AppTheme.deepCrimson),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Export & View Buttons (TXT, DOCX, View Notes)
            Row(
              children: [
                Expanded(
                  child: AnimatedPressButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (modalCtx) {
                          return Container(
                            height: MediaQuery.of(modalCtx).size.height * 0.88,
                            decoration: const BoxDecoration(
                              color: AppTheme.cardWhite,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryYellow,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.auto_stories, color: AppTheme.deepCrimson, size: 26),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          isHindiUi ? 'द्विभाषी नोट्स - पूर्वावलोकन' : 'Bilingual Classroom Notes Preview',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepCrimson),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: AppTheme.deepCrimson),
                                        onPressed: () => Navigator.of(modalCtx).pop(),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(20),
                                    child: SelectableText(
                                      docPreviewText,
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.5, color: AppTheme.textDark),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    backgroundColor: Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    boxShadow: const [],
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('View Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedPressButton(
                    onPressed: _isExporting
                        ? null
                        : () async {
                            setState(() => _isExporting = true);
                            try {
                              final file = await NotesGeneratorService.exportTxtFile(
                                sessionLogs: appState.sessionLogs,
                                targetLanguage: targetLang,
                                lessonTopic: _topicController.text,
                                teacherName: _teacherController.text,
                                teacherSchool: appState.teacherSchool,
                                teacherDesignation: appState.teacherDesignation,
                                teacherEmail: appState.teacherEmail,
                              );
                              setState(() {
                                _exportedFilePath = file.path;
                                _isExporting = false;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isHindiUi
                                          ? 'पाठ्य फ़ाइल (.txt) सहेजी गई: ${file.path}'
                                          : 'Text document (.txt) saved to: ${file.path}',
                                    ),
                                    backgroundColor: AppTheme.deepCrimson,
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() => _isExporting = false);
                            }
                          },
                    backgroundColor: AppTheme.lightCream,
                    foregroundColor: AppTheme.deepCrimson,
                    border: Border.all(color: AppTheme.borderSubtle),
                    boxShadow: const [],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description, color: AppTheme.deepCrimson, size: 16),
                        const SizedBox(width: 4),
                        Text(isHindiUi ? 'TXT फ़ाइल' : 'Export .TXT', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedPressButton(
                    onPressed: _isExporting
                        ? null
                        : () async {
                            setState(() => _isExporting = true);
                            try {
                              final file = await NotesGeneratorService.exportDocxFile(
                                sessionLogs: appState.sessionLogs,
                                targetLanguage: targetLang,
                                lessonTopic: _topicController.text,
                                teacherName: _teacherController.text,
                                teacherSchool: appState.teacherSchool,
                                teacherDesignation: appState.teacherDesignation,
                                teacherEmail: appState.teacherEmail,
                              );
                              setState(() {
                                _exportedFilePath = file.path;
                                _isExporting = false;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isHindiUi
                                          ? 'वर्ड फ़ाइल (.docx) सहेजी गई: ${file.path}'
                                          : 'Word document (.docx) saved to: ${file.path}',
                                    ),
                                    backgroundColor: AppTheme.deepCrimson,
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() => _isExporting = false);
                            }
                          },
                    backgroundColor: AppTheme.deepCrimson,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.article, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(isHindiUi ? 'Word (.docx)' : 'Export .DOCX', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_exportedFilePath != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'File Saved: $_exportedFilePath',
                        style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Live Document Preview Container
            Text(
              isHindiUi ? 'द्विभाषी नोट्स पूर्वावलोकन (Live Preview):' : 'Bilingual Document Live Preview:',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: const [
                  BoxShadow(color: Color(0x10800000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: SelectableText(
                docPreviewText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppTheme.textDark,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
