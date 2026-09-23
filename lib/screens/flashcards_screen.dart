import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final flashcards = appState.flashcards;
    final isHindiUi = appState.uiLanguage == AppUiLanguage.hindi;
    final targetLang = appState.targetLanguage;

    if (flashcards.isEmpty) {
      return Center(
        child: Text(
          isHindiUi ? 'कोई फ़्लैशकार्ड उपलब्ध नहीं हैं।' : 'No flashcards loaded from SQLite database.',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final currentCard = flashcards[_currentIndex];

    return Container(
      color: const Color(0xFFF9F6F0),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindiUi ? 'सत्र शब्दावली फ़्लैशकार्ड्स' : 'Vernacular Learning Flashcards',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.deepCrimson,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${flashcards.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Interactive Animated Flashcard Container
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isFlipped = !_isFlipped;
                });
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Container(
                  key: ValueKey('card_${currentCard.id}_$_isFlipped'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F800000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentCard.iconSymbol,
                        style: const TextStyle(fontSize: 76),
                      ),
                      const SizedBox(height: 20),
                      if (!_isFlipped) ...[
                        Text(
                          currentCard.hindiWord,
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentCard.englishMeaning,
                          style: const TextStyle(fontSize: 16, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.lightCream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.touch_app, size: 18, color: AppTheme.deepCrimson),
                              const SizedBox(width: 8),
                              Text(
                                isHindiUi ? 'अनुवाद देखने के लिए कार्ड दबाएं' : 'Tap Card to Flip for Vernacular Text',
                                style: const TextStyle(color: AppTheme.deepCrimson, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          currentCard.tribalWord,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppTheme.deepCrimson),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phonetic: ${currentCard.phonetic}',
                          style: const TextStyle(fontSize: 15, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.lightCream,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Hindi: ${currentCard.exampleSentenceHindi}',
                                style: const TextStyle(color: AppTheme.textDark, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tribal: ${currentCard.exampleSentenceTribal}',
                                style: const TextStyle(color: AppTheme.deepCrimson, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedPressButton(
                          onPressed: () {
                            appState.speechService.speakTribalText(currentCard.tribalWord, targetLang);
                          },
                          backgroundColor: AppTheme.deepCrimson,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.volume_up, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(isHindiUi ? 'आवाज़ सुनें' : 'Listen Pronunciation'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Next / Previous Card Navigation Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimatedPressButton(
                onPressed: _currentIndex > 0
                    ? () {
                        setState(() {
                          _currentIndex--;
                          _isFlipped = false;
                        });
                      }
                    : null,
                backgroundColor: AppTheme.lightCream,
                foregroundColor: AppTheme.deepCrimson,
                borderRadius: 50,
                padding: const EdgeInsets.all(16),
                boxShadow: const [],
                child: const Icon(Icons.arrow_back, color: AppTheme.deepCrimson),
              ),
              AnimatedPressButton(
                onPressed: _currentIndex < flashcards.length - 1
                    ? () {
                        setState(() {
                          _currentIndex++;
                          _isFlipped = false;
                        });
                      }
                    : null,
                backgroundColor: AppTheme.deepCrimson,
                borderRadius: 50,
                padding: const EdgeInsets.all(16),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
