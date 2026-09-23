import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';

class PhraseBankScreen extends StatefulWidget {
  const PhraseBankScreen({super.key});

  @override
  State<PhraseBankScreen> createState() => _PhraseBankScreenState();
}

class _PhraseBankScreenState extends State<PhraseBankScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // Fetch directly from SQLite phrase bank loaded in AppState
    final phraseBankList = appState.phraseBank;
    final isHindiUi = appState.uiLanguage == AppUiLanguage.hindi;
    final targetLang = appState.targetLanguage;

    final categories = ['All', 'Greetings', 'Instruction', 'Mathematics', 'Science', 'Question', 'Daily Life'];

    final filteredPhrases = phraseBankList.where((item) {
      final matchesCat = _selectedCategory == 'All' || item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          item.hindi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.santhali.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.english.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Container(
      color: const Color(0xFFF9F6F0),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar
          TextField(
            style: const TextStyle(color: AppTheme.textDark),
            decoration: InputDecoration(
              hintText: isHindiUi ? 'वाक्य बैंक में खोजें...' : 'Search classroom phrase bank...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.deepCrimson),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 12),

          // 2. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(cat),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selectedColor: AppTheme.deepCrimson,
                    backgroundColor: AppTheme.lightCream,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Phrase List from SQLite DB
          Expanded(
            child: appState.isLoadingDb
                ? const Center(child: CircularProgressIndicator(color: AppTheme.deepCrimson))
                : filteredPhrases.isEmpty
                    ? Center(
                        child: Text(
                          isHindiUi ? 'कोई वाक्य नहीं मिला।' : 'No matching phrases found.',
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredPhrases.length,
                        itemBuilder: (context, index) {
                          final item = filteredPhrases[index];
                          final translation = item.getTranslationFor(targetLang);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppTheme.cardWhite,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x10800000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightCream,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: const TextStyle(
                                          color: AppTheme.deepCrimson,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.volume_up, color: AppTheme.deepCrimson),
                                      onPressed: () {
                                        appState.speechService.speakTribalText(translation, targetLang);
                                      },
                                      tooltip: 'Play Audio',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.hindi,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.english,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                                ),
                                const Divider(color: AppTheme.borderSubtle, height: 16),
                                Text(
                                  '${targetLang.displayName}:',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.deepCrimson, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  translation,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.deepCrimson),
                                ),
                                if (item.phonetic.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Phonetic: ${item.phonetic}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
