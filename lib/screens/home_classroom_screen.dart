import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/app_models.dart';
import '../services/speech_service.dart';
import '../services/notes_generator_service.dart';
import '../theme/app_theme.dart';
import 'auth/signin_screen.dart';

class HomeClassroomScreen extends StatefulWidget {
  const HomeClassroomScreen({super.key});

  @override
  State<HomeClassroomScreen> createState() => _HomeClassroomScreenState();
}

class _HomeClassroomScreenState extends State<HomeClassroomScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _customTextInputController = TextEditingController();
  late AnimationController _pulseController;

  final List<String> _quickTeacherPhrases = [
    "नमस्ते बच्चों, आप सब कैसे हैं?",
    "आज हम गणित सीखेंगे।",
    "अपनी किताब खोलो।",
    "एक से दस तक गिनती करो।",
    "यह पौधा पानी और धूप से बढ़ता है।",
    "शाबाश! बहुत बढ़िया।",
    "साफ पानी पीना चाहिए।",
  ];

  final List<String> _quickStudentPhrases = [
    "ᱡᱚᱦᱟᱨ ᱜᱚᱝᱠᱮ (Johar - Hello Teacher)",
    "ᱞᱮᱠᱷᱟ ᱤᱧ ᱵᱟᱰᱟᱭᱟ (I know math)",
    "ᱯᱩᱛᱷᱤ ᱤᱧ ᱡᱷᱤ ᱠᱮᱫᱟ (I opened book)",
    "ᱫᱟᱜ ᱤᱧ ᱧᱩᱭᱟ? (Can I drink water?)",
    "ᱢᱤᱫ, ᱵᱟᱨ, ᱯᱮ, ᱯᱳᱱ (1, 2, 3, 4)",
    "ᱤᱧ ᱵᱩᱡᱷᱟᱹᱣ ᱠᱮᱫᱟ (I understood)",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final speechService = Provider.of<AppState>(context, listen: false).speechService;
        speechService.initializeSpeech();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final speechService = Provider.of<AppState>(context, listen: false).speechService;
      speechService.reEngageMicIfEnabled();
    }
  }

  String _getTimeBasedGreeting(bool isHindiUi) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return isHindiUi ? 'शुभ प्रभात' : 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return isHindiUi ? 'शुभ दोपहर' : 'Good Afternoon';
    } else if (hour >= 17 && hour < 22) {
      return isHindiUi ? 'शुभ संध्या' : 'Good Evening';
    } else {
      return isHindiUi ? 'शुभ रात्रि' : 'Good Night';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _customTextInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext meContext) {
    final appState = Provider.of<AppState>(meContext);
    final speechService = appState.speechService;
    final isHindiUi = appState.uiLanguage == AppUiLanguage.hindi;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Sunflower Yellow Header Banner with Crimson Curve Overlay
          _buildYellowHeaderBanner(meContext, appState, isHindiUi),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2. Main Floating Card matching reference image
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _buildMainTranslationControlCard(meContext, appState, speechService, isHindiUi),
                ),

                const SizedBox(height: 10),

                // 3. Live Translation Subtitle Stage Card
                _buildLiveSubtitleStageCard(meContext, appState, isHindiUi),

                const SizedBox(height: 20),

                // 4. Quick Santhali Classroom Phrases Chips
                _buildQuickPhraseBank(meContext, appState, isHindiUi),

                const SizedBox(height: 20),

                // 5. Manual Speech/Text Input Field
                _buildManualTextInput(meContext, appState, isHindiUi),

                const SizedBox(height: 24),

                // 6. Live Session Timeline & Notes
                _buildSessionTimeline(meContext, appState, isHindiUi),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Top Sunflower Yellow Header Banner with Curved Maroon Arch Accent
  Widget _buildYellowHeaderBanner(BuildContext context, AppState appState, bool isHindiUi) {
    final currentUser = appState.currentUser;

    return Container(
      width: double.infinity,
      color: AppTheme.primaryYellow,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: AppTheme.deepCrimson,
                borderRadius: BorderRadius.circular(120),
              ),
            ),
          ),
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.darkCrimson,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 50),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_getTimeBasedGreeting(isHindiUi)} !',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepCrimson,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.deepCrimson,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.waving_hand_rounded,
                                color: AppTheme.primaryYellow,
                                size: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser != null
                              ? currentUser.name
                              : (isHindiUi ? 'शिक्षक' : 'Teacher'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.deepCrimson,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Target: ${appState.targetLanguage.displayName}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (currentUser != null && currentUser.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade800,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text('Verified Teacher', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      if (currentUser == null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignInScreen()),
                        );
                      } else {
                        _showUserProfileModal(context, appState);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.cardWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x20800000), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Icon(
                        currentUser == null ? Icons.person_outline : Icons.account_circle,
                        color: AppTheme.deepCrimson,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Main Floating White Card
  Widget _buildMainTranslationControlCard(
      BuildContext context, AppState appState, SpeechService speechService, bool isHindiUi) {
    final isTeacher = appState.isTeacherMode;
    final isListening = speechService.isListening;
    final speechRate = speechService.speechRate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F800000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isTeacher) appState.toggleTeacherMode();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isTeacher ? AppTheme.deepCrimson : AppTheme.lightCream,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isTeacher ? AppTheme.deepCrimson : AppTheme.borderSubtle,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isHindiUi ? 'शिक्षक मोड' : 'Teacher Mode',
                        style: TextStyle(
                          color: isTeacher ? Colors.white : AppTheme.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isTeacher) appState.toggleTeacherMode();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !isTeacher ? AppTheme.deepCrimson : AppTheme.lightCream,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: !isTeacher ? AppTheme.deepCrimson : AppTheme.borderSubtle,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isHindiUi ? 'छात्र मोड' : 'Student Mode',
                        style: TextStyle(
                          color: !isTeacher ? Colors.white : AppTheme.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.lightCream.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked, color: AppTheme.primaryYellow, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindiUi ? 'स्रोत भाषा (बोलें)' : 'From (Source Speech)',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isTeacher ? 'Hindi (हिंदी)' : appState.targetLanguage.displayName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepCrimson),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 4, bottom: 4),
                      child: Divider(color: AppTheme.borderSubtle, height: 16),
                    ),

                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindiUi ? 'लक्ष्य अनुवाद' : 'To (Vernacular Target)',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isTeacher ? appState.targetLanguage.displayName : 'Hindi (हिंदी)',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepCrimson),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                Positioned(
                  right: 0,
                  top: 24,
                  child: GestureDetector(
                    onTap: () => appState.toggleTeacherMode(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.lightCream,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x15800000), blurRadius: 6),
                        ],
                      ),
                      child: const Icon(Icons.swap_vert, color: AppTheme.deepCrimson, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.lightCream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, color: AppTheme.deepCrimson, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Voice Speed', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                            Text(
                              '${speechRate.toStringAsFixed(2)}x Clear & Slow',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: speechService.outputDevice == AudioOutputDevice.bluetoothSpeaker
                      ? AppTheme.deepCrimson
                      : AppTheme.lightCream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    speechService.outputDevice == AudioOutputDevice.bluetoothSpeaker
                        ? Icons.bluetooth_audio
                        : Icons.volume_up,
                    color: speechService.outputDevice == AudioOutputDevice.bluetoothSpeaker
                        ? Colors.white
                        : AppTheme.deepCrimson,
                    size: 20,
                  ),
                  onPressed: () => speechService.toggleAudioOutputDevice(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Professional Studio Recorder UI Deck
          Builder(
            builder: (context) {
              final isHardwareMic = speechService.isHardwareMicListening;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: isListening
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF1E0305),
                            Colors.red.shade900,
                            const Color(0xFF2D0509),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [
                            AppTheme.lightCream,
                            Color(0xFFFFF7EA),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isListening
                        ? (isHardwareMic ? Colors.redAccent : Colors.amber)
                        : AppTheme.borderSubtle,
                    width: isListening ? 2 : 1.5,
                  ),
                  boxShadow: isListening
                      ? [
                          BoxShadow(
                            color: (isHardwareMic ? Colors.red.shade700 : Colors.amber.shade700).withValues(alpha: 0.35),
                            blurRadius: 22,
                            spreadRadius: 3,
                            offset: const Offset(0, 8),
                          )
                        ]
                      : [
                          const BoxShadow(
                            color: Color(0x10800000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                ),
                child: Column(
                  children: [
                    // Top Studio Console Bar: Status LED & Master Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final glow = isListening ? (0.6 + 0.4 * _pulseController.value) : 1.0;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isListening
                                        ? (isHardwareMic
                                            ? Colors.red.shade900.withValues(alpha: glow)
                                            : Colors.amber.shade900.withValues(alpha: glow))
                                        : AppTheme.cardWhite,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isListening
                                          ? (isHardwareMic ? Colors.redAccent : Colors.amberAccent)
                                          : AppTheme.borderSubtle,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: isListening
                                              ? (isHardwareMic ? Colors.redAccent : Colors.amberAccent)
                                              : Colors.grey.shade400,
                                          shape: BoxShape.circle,
                                          boxShadow: isListening
                                              ? [
                                                  BoxShadow(
                                                    color: isHardwareMic ? Colors.redAccent : Colors.amberAccent,
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  )
                                                ]
                                              : [],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isListening
                                            ? (isHardwareMic
                                                ? (isHindiUi ? 'REC LIVE (16kHz VAD)' : 'REC LIVE • 16kHz STUDIO')
                                                : (isHindiUi ? 'CONNECTING...' : 'RE-ENGAGING MIC...'))
                                            : (isHindiUi ? 'STANDBY MODE' : 'RECORDER STANDBY'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: isListening ? Colors.white : AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              isListening ? (isHindiUi ? 'चालू' : 'LIVE') : (isHindiUi ? 'बंद' : 'OFF'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isListening ? Colors.white70 : AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Switch.adaptive(
                              value: isListening,
                              activeThumbColor: Colors.white,
                              activeTrackColor: Colors.redAccent,
                              inactiveThumbColor: AppTheme.deepCrimson,
                              inactiveTrackColor: AppTheme.cardWhite,
                              onChanged: (_) => _toggleContinuousListening(appState, speechService),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Central Studio Audio Spectrum / Waveform Visualizer & Deck Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Left Waveform Bars
                        _buildWaveformBars(isListening, isLeft: true),

                        // Centerpiece Studio Record Button
                        GestureDetector(
                          onTap: () => _toggleContinuousListening(appState, speechService),
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = isListening ? (1.0 + 0.05 * _pulseController.value) : 1.0;
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 82,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isListening
                                        ? const LinearGradient(
                                            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : const LinearGradient(
                                            colors: [AppTheme.deepCrimson, AppTheme.darkCrimson],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isListening ? Colors.redAccent : AppTheme.deepCrimson)
                                            .withValues(alpha: isListening ? 0.6 : 0.3),
                                        blurRadius: isListening ? 20 : 10,
                                        spreadRadius: isListening ? 4 : 1,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      width: isListening ? 26 : 36,
                                      height: isListening ? 26 : 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(isListening ? 6 : 18),
                                      ),
                                      child: isListening
                                          ? Icon(
                                              Icons.stop_rounded,
                                              color: Colors.red.shade900,
                                              size: 20,
                                            )
                                          : const Icon(
                                              Icons.mic_rounded,
                                              color: AppTheme.deepCrimson,
                                              size: 22,
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Right Waveform Bars
                        _buildWaveformBars(isListening, isLeft: false),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      isListening
                          ? (isHindiUi
                              ? '🔴 निरंतर रिकॉर्डिंग चालू है (माइक हमेशा सुन रहा है)'
                              : '🔴 Continuous Studio Recording Active (Tap to Stop)')
                          : (isHindiUi
                              ? 'रिकॉर्डर शुरू करने के लिए बटन या स्विच दबाएं'
                              : 'Tap Studio Mic Button to Start Continuous Recording'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isListening ? Colors.white70 : AppTheme.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 14),

                    // Full-width Professional Action Button
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedPressButton(
                        onPressed: () => _toggleContinuousListening(appState, speechService),
                        backgroundColor: isListening ? Colors.white : AppTheme.deepCrimson,
                        foregroundColor: isListening ? Colors.red.shade900 : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        borderRadius: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isListening ? Icons.stop_circle_rounded : Icons.fiber_manual_record_rounded,
                              size: 18,
                              color: isListening ? Colors.red.shade900 : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isListening
                                  ? (isHindiUi ? 'रिकॉर्डिंग बंद करें (STOP RECORDING)' : 'STOP STUDIO RECORDING')
                                  : (isHindiUi ? 'रिकॉर्डिंग शुरू करें (START RECORDING)' : 'START CONTINUOUS RECORDING'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 3. Live Translation Subtitle Stage Card
  Widget _buildLiveSubtitleStageCard(BuildContext context, AppState appState, bool isHindiUi) {
    final isTeacher = appState.isTeacherMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15800000),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.deepCrimson,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isTeacher
                            ? (isHindiUi ? 'लाइव अनुवाद मंच (हिंदी ➔ संथाली)' : 'Real-Time Subtitles (Hindi ➔ Santali)')
                            : (isHindiUi ? 'लाइव अनुवाद मंच (संथाली ➔ हिंदी)' : 'Real-Time Subtitles (Santali ➔ Hindi)'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightCream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  appState.currentSource.label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.deepCrimson),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            isTeacher
                ? (isHindiUi ? 'शिक्षक का वक्तव्य (हिंदी):' : 'Teacher Speech Input (Hindi):')
                : (isHindiUi ? 'छात्र का वक्तव्य (संथाली):' : 'Student Speech Input (Santali):'),
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightCream.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              appState.livePartialHindiText.isNotEmpty
                  ? '🎙️ ${appState.livePartialHindiText}'
                  : (appState.currentInputText.isEmpty
                      ? (isTeacher
                          ? (isHindiUi ? 'माइक दबाएं और पाठ पढ़ाना शुरू करें...' : 'Click continuous mic to start speaking...')
                          : (isHindiUi ? 'संथाली में बोलें या प्रश्न पूछें...' : 'Click continuous mic to speak Santali...'))
                      : appState.currentInputText),
              style: TextStyle(
                fontSize: 16,
                color: appState.livePartialHindiText.isNotEmpty ? AppTheme.deepCrimson : AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            isTeacher
                ? '${appState.targetLanguage.displayName} Translation (Ol Chiki ᱥᱟᱱᱛᱟᱲᱤ):'
                : (isHindiUi ? 'हिंदी उपशीर्षक / अनुवाद:' : 'Hindi Subtitles / Translation:'),
            style: const TextStyle(fontSize: 11, color: AppTheme.deepCrimson, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.deepCrimson,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appState.currentTranslatedText.isEmpty
                      ? (isHindiUi ? 'अनुवाद यहाँ दिखेगा...' : 'Live translation output will appear here...')
                      : appState.currentTranslatedText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (appState.currentPhoneticText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Phonetic: ${appState.currentPhoneticText}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryYellow, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Quick Santhali Phrase Bank Chips
  Widget _buildQuickPhraseBank(BuildContext context, AppState appState, bool isHindiUi) {
    final isTeacher = appState.isTeacherMode;
    final activePhrases = isTeacher ? _quickTeacherPhrases : _quickStudentPhrases;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTeacher
              ? (isHindiUi ? 'त्वरित शिक्षक वाक्य (क्लिक करें):' : 'Quick Teacher Classroom Phrases:')
              : (isHindiUi ? 'त्वरित छात्र संथाली वाक्य (क्लिक करें):' : 'Quick Student Santali Phrases:'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: activePhrases.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final phrase = activePhrases[index];
              return AnimatedPressButton(
                onPressed: () => appState.processTranslation(phrase),
                backgroundColor: AppTheme.lightCream,
                foregroundColor: AppTheme.deepCrimson,
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                boxShadow: const [],
                border: Border.all(color: AppTheme.borderSubtle),
                child: Text(phrase, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 5. Manual Speech/Text Input Field
  Widget _buildManualTextInput(BuildContext context, AppState appState, bool isHindiUi) {
    final isTeacher = appState.isTeacherMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x15800000), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTeacher
                ? (isHindiUi ? 'कस्टम शिक्षक पाठ टाइप करें:' : 'Teacher Custom Sentence Input:')
                : (isHindiUi ? 'कस्टम छात्र वाक्य टाइप करें:' : 'Student Custom Sentence Input:'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customTextInputController,
                  decoration: InputDecoration(
                    hintText: isTeacher
                        ? (isHindiUi ? 'जैसे: आज हम गणित पढ़ेंगे...' : 'Type Hindi sentence...')
                        : (isHindiUi ? 'जैसे: ᱡᱚᱦᱟᱨ ᱜᱚᱝᱠᱮ / Johar...' : 'Type Santali sentence (Ol Chiki / Roman)...'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedPressButton(
                onPressed: () {
                  final text = _customTextInputController.text.trim();
                  if (text.isNotEmpty) {
                    appState.processTranslation(text);
                    _customTextInputController.clear();
                  }
                },
                backgroundColor: AppTheme.deepCrimson,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: const Text('Translate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Inline Formatted Structured Notes Viewer Modal
  void _showInlineNotesViewDialog(BuildContext context, AppState appState) {
    final isHindiUi = appState.uiLanguage == AppUiLanguage.hindi;
    final docContent = NotesGeneratorService.generateBilingualDocContent(
      sessionLogs: appState.sessionLogs,
      targetLanguage: appState.targetLanguage,
      lessonTopic: appState.currentLessonTopic,
      teacherName: appState.teacherName,
    );

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
              // Modal Handle & Header Bar
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
                        isHindiUi ? 'कक्षा अध्ययन नोट्स - पूर्वावलोकन' : 'Classroom Structured Study Notes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepCrimson,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.deepCrimson),
                      onPressed: () => Navigator.of(modalCtx).pop(),
                    ),
                  ],
                ),
              ),

              // Formatted Content Box
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(
                    docContent,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.5,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),

              // Action Footer Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.lightCream,
                  border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedPressButton(
                        onPressed: () async {
                          final file = await NotesGeneratorService.exportTxtFile(
                            sessionLogs: appState.sessionLogs,
                            targetLanguage: appState.targetLanguage,
                            lessonTopic: appState.currentLessonTopic,
                            teacherName: appState.teacherName,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Saved .TXT to Downloads:\n${file.path}'),
                                backgroundColor: AppTheme.deepCrimson,
                              ),
                            );
                          }
                        },
                        backgroundColor: Colors.brown.shade800,
                        foregroundColor: Colors.white,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Text('.TXT Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedPressButton(
                        onPressed: () async {
                          final file = await NotesGeneratorService.exportSingleDocxFile(
                            sessionLogs: appState.sessionLogs,
                            targetLanguage: appState.targetLanguage,
                            lessonTopic: appState.currentLessonTopic,
                            teacherName: appState.teacherName,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Saved .DOCX to Downloads:\n${file.path}'),
                                backgroundColor: AppTheme.deepCrimson,
                              ),
                            );
                          }
                        },
                        backgroundColor: AppTheme.deepCrimson,
                        foregroundColor: Colors.white,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Text('.DOCX Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 6. Live Session Timeline & Single File Download Confirmation
  Widget _buildSessionTimeline(BuildContext context, AppState appState, bool isHindiUi) {
    final logs = appState.sessionLogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isHindiUi ? 'कक्षा सत्र रिकॉर्ड (लाइव सेविंग...)' : 'Live Classroom Speech Timeline',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (logs.isNotEmpty) ...[
              const SizedBox(width: 6),
              AnimatedPressButton(
                onPressed: () => _showInlineNotesViewDialog(context, appState),
                backgroundColor: Colors.teal.shade800,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                boxShadow: const [],
                child: const Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('View Notes', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              AnimatedPressButton(
                onPressed: () async {
                  try {
                    final file = await NotesGeneratorService.downloadLiveHindiNotesTxt(
                      sessionLogs: appState.sessionLogs,
                      targetLanguage: appState.targetLanguage,
                      lessonTopic: appState.currentLessonTopic,
                      teacherName: appState.teacherName,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Raw Speech Notes (.txt) saved to Downloads:\n${file.path}'),
                          backgroundColor: Colors.brown.shade800,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Download error: $e');
                  }
                },
                backgroundColor: Colors.brown.shade800,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                boxShadow: const [],
                child: const Row(
                  children: [
                    Icon(Icons.text_snippet, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('.TXT Notes', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              AnimatedPressButton(
                onPressed: () => _showExportConfirmationDialog(context, appState),
                backgroundColor: AppTheme.deepCrimson,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                boxShadow: const [],
                child: const Row(
                  children: [
                    Icon(Icons.file_download, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('.DOCX Study Material', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              AnimatedPressButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(isHindiUi ? 'नोट्स साफ़ करें?' : 'Clear Session Notes?'),
                      content: Text(isHindiUi
                          ? 'क्या आप इस सत्र के सभी भाषण नोट्स को हटाना चाहते हैं?'
                          : 'Are you sure you want to clear all recorded notes for this session?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                          child: Text(isHindiUi ? 'रद्द करें' : 'Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(dialogCtx).pop(true),
                          child: Text(isHindiUi ? 'साफ़ करें' : 'Clear'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await appState.clearSessionNotes();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isHindiUi ? 'सत्र के नोट्स साफ़ कर दिए गए हैं।' : 'Session notes cleared successfully!'),
                          backgroundColor: Colors.red.shade800,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                backgroundColor: Colors.red.shade900,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                boxShadow: const [],
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(isHindiUi ? 'साफ़ करें' : 'Clear Notes',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.lightCream.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Center(
              child: Text(
                isHindiUi ? 'अभी तक कोई भाषण अनुवाद नहीं हुआ है।' : 'No speech recorded yet in this session.',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = logs[index];
              final isSantaliSource = item.isOriginalSantali || (!appState.isTeacherMode && !RegExp(r'[\u0900-\u097F]').hasMatch(item.originalText));
              final srcLabel = isSantaliSource ? 'Santhali' : 'Hindi';
              final tgtLabel = isSantaliSource ? 'Hindi' : 'Santhali';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$srcLabel: ${item.originalText}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$tgtLabel: ${item.translatedText}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.deepCrimson),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showExportConfirmationDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDownloading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: AppTheme.cardWhite,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.lightCream,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.file_download_outlined, size: 40, color: AppTheme.deepCrimson),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Download Study Material (.docx)?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will generate and save a single structured Word document containing all recorded session speech (Hindi 1st ➔ Santhali next) along with synopses and dictionary.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.lightCream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.book, size: 16, color: AppTheme.deepCrimson),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Topic: ${appState.currentLessonTopic}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: AppTheme.deepCrimson),
                              const SizedBox(width: 8),
                              Text(
                                'Teacher: ${appState.teacherName}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.graphic_eq, size: 16, color: AppTheme.deepCrimson),
                              const SizedBox(width: 8),
                              Text(
                                'Total Sentences: ${appState.sessionLogs.length}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _showInlineNotesViewDialog(context, appState);
                            },
                            child: const Text('View Notes', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AnimatedPressButton(
                            isLoading: isDownloading,
                            onPressed: () async {
                              setDialogState(() => isDownloading = true);
                              try {
                                final file = await NotesGeneratorService.exportSingleDocxFile(
                                  sessionLogs: appState.sessionLogs,
                                  targetLanguage: appState.targetLanguage,
                                  lessonTopic: appState.currentLessonTopic,
                                  teacherName: appState.teacherName,
                                );
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Study Material Word file (.docx) downloaded to Downloads:\n${file.path}'),
                                      backgroundColor: AppTheme.deepCrimson,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setDialogState(() => isDownloading = false);
                              }
                            },
                            backgroundColor: AppTheme.deepCrimson,
                            child: const Text('Confirm & Download', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleContinuousListening(AppState appState, SpeechService speechService) {
    if (speechService.isListening) {
      speechService.stopContinuousListening();
    } else {
      speechService.startContinuousTeacherSpeechStream(
        onChunkRecognized: (text) {
          appState.processTranslation(text);
        },
        onPartialRecognized: (partial) {
          appState.updateLivePartialText(partial);
        },
      );
    }
  }

  void _showUserProfileModal(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppTheme.cardWhite,
      builder: (context) {
        final user = appState.currentUser!;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle, size: 60, color: AppTheme.deepCrimson),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              Text(
                user.email,
                style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AnimatedPressButton(
                  onPressed: () {
                    appState.signOut();
                    Navigator.of(context).pop();
                  },
                  backgroundColor: Colors.red.shade700,
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaveformBars(bool isListening, {required bool isLeft}) {
    const barCount = 5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(barCount, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final cycle = (index * 0.2 + (isLeft ? 0.0 : 0.5)) % 1.0;
            final val = (cycle + _pulseController.value) % 1.0;
            final height = isListening
                ? (8.0 + 22.0 * (0.5 + 0.5 * (val - 0.5).abs()))
                : (6.0 + (index % 3) * 3.0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: isListening
                    ? Colors.white.withValues(alpha: 0.6 + 0.4 * (val > 0.5 ? 1.0 : 0.5))
                    : AppTheme.deepCrimson.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }
}
