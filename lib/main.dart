import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'models/app_models.dart';
import 'theme/app_theme.dart';
import 'screens/home_classroom_screen.dart';
import 'screens/phrase_bank_screen.dart';
import 'screens/flashcards_screen.dart';
import 'screens/bilingual_notes_screen.dart';
import 'screens/dataset_models_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const VernacularPedagogyApp(),
    ),
  );
}

class VernacularPedagogyApp extends StatelessWidget {
  const VernacularPedagogyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vernacular Pedagogy - Vernacular Translation Bridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationFrame(),
    );
  }
}

class MainNavigationFrame extends StatefulWidget {
  const MainNavigationFrame({super.key});

  @override
  State<MainNavigationFrame> createState() => _MainNavigationFrameState();
}

class _MainNavigationFrameState extends State<MainNavigationFrame> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeClassroomScreen(),
    const PhraseBankScreen(),
    const FlashcardsScreen(),
    const BilingualNotesScreen(),
    const DatasetModelsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isHindiUi = appState.uiLanguage == AppUiLanguage.hindi;

    final navTitles = isHindiUi
        ? ['लाइव कक्षा', 'वाक्य बैंक', 'फ़्लैशकार्ड्स', 'द्विभाषी नोट्स', 'डेटासेट व मॉडल']
        : ['Live Class', 'Phrase Bank', 'Flashcards', 'Bilingual Notes', 'Datasets & Models'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryYellow,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHindiUi ? 'मातृभाषा शिक्षा अनुवादक' : 'Vernacular Pedagogy Bridge',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepCrimson),
            ),
            Text(
              'SIH26042 • Real-Time AI Platform (${appState.targetLanguage.displayName})',
              style: const TextStyle(fontSize: 10, color: AppTheme.textDark, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          // UI Language Selector Toggle (Hindi / English)
          TextButton.icon(
            onPressed: () {
              appState.setUiLanguage(
                appState.uiLanguage == AppUiLanguage.english ? AppUiLanguage.hindi : AppUiLanguage.english,
              );
            },
            icon: const Icon(Icons.language, color: AppTheme.deepCrimson, size: 18),
            label: Text(
              appState.uiLanguage == AppUiLanguage.english ? 'हिन्दी UI' : 'English UI',
              style: const TextStyle(color: AppTheme.deepCrimson, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),

          // Target Tribal Language Selector Dropdown (Santhali, Ho, Mundari)
          PopupMenuButton<TargetLanguage>(
            icon: const Icon(Icons.tune, color: AppTheme.deepCrimson),
            tooltip: 'Select Target Tribal Language',
            onSelected: (lang) => appState.setTargetLanguage(lang),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TargetLanguage.santhali,
                child: Text('Santhali (ᱥᱟᱱᱛᱟᱲᱤ / संथाली)'),
              ),
              const PopupMenuItem(
                value: TargetLanguage.ho,
                child: Text('Ho (ᱦᱳ / हो)'),
              ),
              const PopupMenuItem(
                value: TargetLanguage.mundari,
                child: Text('Mundari (मुंडारी)'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardWhite,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A800000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.cardWhite,
          selectedItemColor: AppTheme.deepCrimson,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_rounded, 0),
              label: navTitles[0],
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.collections_bookmark_rounded, 1),
              label: navTitles[1],
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.style_rounded, 2),
              label: navTitles[2],
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.assignment_rounded, 3),
              label: navTitles[3],
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.dataset_rounded, 4),
              label: navTitles[4],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.lightCream : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: isSelected ? AppTheme.deepCrimson : AppTheme.textMuted,
        size: 22,
      ),
    );
  }
}
