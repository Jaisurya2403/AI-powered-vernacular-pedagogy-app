import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/app_models.dart';
import '../services/notes_generator_service.dart';
import '../engine/voice_biometrics_engine.dart';
import '../theme/app_theme.dart';
import 'auth/signin_screen.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final isHindiUi = appState.uiLanguage == AppUiLanguage.hindi;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F6F0),
        appBar: AppBar(
          backgroundColor: AppTheme.primaryYellow,
          elevation: 0,
          title: Text(
            isHindiUi ? 'शिक्षक प्रोफ़ाइल' : 'Teacher Profile',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepCrimson),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.deepCrimson, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.lightCream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Icon(Icons.lock_person_outlined, size: 64, color: AppTheme.deepCrimson),
                ),
                const SizedBox(height: 20),
                Text(
                  isHindiUi ? 'लॉग इन आवश्यक है' : 'Sign In Required',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  isHindiUi
                      ? 'अपने शिक्षण सत्र का इतिहास, नोट्स और आवाज़ प्रोफ़ाइल को सुरक्षित रूप से सहेजने के लिए कृपया साइन इन करें।'
                      : 'Sign in to persistently save your teaching history, study notes, and personal voice assistant profile.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepCrimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.login),
                    label: Text(
                      isHindiUi ? 'साइन इन / रजिस्टर करें' : 'Sign In / Register',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryYellow,
        elevation: 0,
        title: Text(
          isHindiUi ? 'शिक्षक प्रोफ़ाइल व इतिहास' : 'Teacher Profile & History',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepCrimson, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.deepCrimson, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: isHindiUi ? 'लॉग आउट' : 'Sign Out',
            icon: const Icon(Icons.logout, color: AppTheme.deepCrimson),
            onPressed: () => _confirmSignOut(context, appState, isHindiUi),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.deepCrimson,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.deepCrimson,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.person, size: 20),
              text: isHindiUi ? 'प्रोफ़ाइल व आवाज़' : 'Profile & Voice',
            ),
            Tab(
              icon: const Icon(Icons.history_edu, size: 20),
              text: isHindiUi ? 'कक्षा इतिहास (${appState.userTeachingHistory.length})' : 'Teaching History (${appState.userTeachingHistory.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Profile & Voice Biometrics Assistant
          _buildProfileAndVoiceTab(context, appState, user, isHindiUi),

          // Tab 2: Teaching History & Notes
          _buildTeachingHistoryTab(context, appState, user, isHindiUi),
        ],
      ),
    );
  }

  // ── TAB 1: Profile & Voice Biometrics ───────────────────────────────────────
  Widget _buildProfileAndVoiceTab(BuildContext context, AppState appState, UserModel user, bool isHindiUi) {
    final hasVoice = appState.hasEnrolledVoice;

    return SingleChildScrollView(

      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Teacher Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x15800000), blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.lightCream,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, size: 36, color: AppTheme.deepCrimson),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (user.isVerified)
                                const Icon(Icons.verified, color: Colors.green, size: 18),
                            ],
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.school,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.deepCrimson),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: isHindiUi ? 'प्रोफ़ाइल बदलें' : 'Edit Profile',
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.deepCrimson),
                      onPressed: () => _showEditProfileDialog(context, appState, user, isHindiUi),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. Personal Voice Assistant & Biometric Matcher Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasVoice
                    ? [const Color(0xFF1E3A1E), const Color(0xFF0F260F)]
                    : [AppTheme.cardWhite, AppTheme.lightCream],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hasVoice ? Colors.greenAccent.shade400 : AppTheme.borderSubtle,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasVoice ? Colors.green.withValues(alpha: 0.25) : const Color(0x10800000),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasVoice ? Colors.green.shade800 : AppTheme.lightCream,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasVoice ? Icons.mic : Icons.mic_none,
                        color: hasVoice ? Colors.white : AppTheme.deepCrimson,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindiUi ? 'व्यक्तिगत आवाज़ सहायक' : 'Personal Voice Assistant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasVoice ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                          Text(
                            hasVoice
                                ? (isHindiUi ? 'सक्रिय (75% मिलान फ़िल्टर)' : 'Active (75% Match Verification)')
                                : (isHindiUi ? 'नामांकन नहीं हुआ (वैकल्पिक)' : 'Not Enrolled (Optional)'),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasVoice ? Colors.greenAccent : AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasVoice)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '75% SHIELD',
                          style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  hasVoice
                      ? (isHindiUi
                          ? 'आपकी आवाज़ प्रोफ़ाइल सुरक्षित रूप से सहेजी गई है। कक्षा के दौरान केवल आपकी आवाज़ (75%+ मिलान) ही अनुवादित होगी, जिससे पृष्ठभूमि का शोर समाप्त रहेगा।'
                          : 'Your unique voice profile is saved. Classroom speech recognition verifies your voice against a 75% threshold, blocking background student voices.')
                      : (isHindiUi
                          ? 'कक्षा में छात्रों के शोर को फ़िल्टर करने और केवल अपनी आवाज़ को पहचानने के लिए एक बार आवाज़ का नमूना दर्ज करें।'
                          : 'Enroll your voice sample so the system recognizes only your speech and suppresses surrounding student voices.'),
                  style: TextStyle(
                    fontSize: 12,
                    color: hasVoice ? Colors.white70 : AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasVoice ? Colors.green.shade700 : AppTheme.deepCrimson,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(hasVoice ? Icons.graphic_eq : Icons.add_circle_outline, size: 18),
                        label: Text(
                          hasVoice
                              ? (isHindiUi ? 'आवाज़ बदलें / री-रिकॉर्ड' : 'Re-record Voice')
                              : (isHindiUi ? 'आवाज़ दर्ज करें' : 'Enroll Voice Profile'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () => _showVoiceEnrollmentDialog(context, appState, isHindiUi),
                      ),
                    ),
                    if (hasVoice) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: isHindiUi ? 'आवाज़ प्रोफ़ाइल हटाएं' : 'Delete Voice Profile',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _confirmDeleteVoice(context, appState, isHindiUi),
                      ),
                    ],
                  ],
                ),
                if (hasVoice) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      side: const BorderSide(color: Colors.greenAccent),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(
                      isHindiUi ? 'आवाज़ सत्यापन का परीक्षण करें (75% चेक)' : 'Test Voice Matcher (75% Check)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () => _showVoiceTestDialog(context, appState, isHindiUi),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── TAB 2: Teaching History & Notes ────────────────────────────────────────
  Widget _buildTeachingHistoryTab(BuildContext context, AppState appState, UserModel user, bool isHindiUi) {
    final history = appState.userTeachingHistory;

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.lightCream,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_edu, size: 54, color: AppTheme.deepCrimson),
              ),
              const SizedBox(height: 16),
              Text(
                isHindiUi ? 'कोई शिक्षण सत्र इतिहास नहीं' : 'No Teaching Sessions Yet',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                isHindiUi
                    ? 'जब आप लाइव कक्षा में पढ़ाएंगे, तो आपके सभी सत्र नोट्स और अध्ययन सामग्री यहाँ स्वचालित रूप से सहेजी जाएगी।'
                    : 'When you teach lessons in the live classroom, your session notes and study documents will be persistently saved here.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = history[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderSubtle),
            boxShadow: const [
              BoxShadow(color: Color(0x10800000), blurRadius: 10, offset: Offset(0, 3)),
            ],
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
                      color: AppTheme.deepCrimson,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${session.dateStr} • ${session.timeStr}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    onPressed: () async {
                      if (session.id != null) {
                        await appState.deleteTeachingSession(session.id!);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                session.topic,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Language: ${session.targetLanguage} • ${session.totalSentences} sentences spoken',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.deepCrimson,
                        side: const BorderSide(color: AppTheme.deepCrimson),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.description, size: 16),
                      label: Text(
                        isHindiUi ? 'नोट्स (.DOCX)' : 'Notes (.DOCX)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        try {
                          final file = await NotesGeneratorService.exportSingleDocxFile(
                            sessionLogs: appState.sessionLogs,
                            targetLanguage: appState.targetLanguage,
                            lessonTopic: session.topic,
                            teacherName: session.teacherName,
                            teacherSchool: user.school,
                            teacherDesignation: user.designation,
                            teacherEmail: user.email,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Word Study Material (.docx) saved to Downloads:\n${file.path}'),
                                backgroundColor: AppTheme.deepCrimson,
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Export error: $e');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.text_snippet, size: 16),
                      label: Text(
                        isHindiUi ? 'कच्चे नोट्स (.TXT)' : 'Raw (.TXT)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        try {
                          final file = await NotesGeneratorService.downloadLiveHindiNotesTxt(
                            sessionLogs: appState.sessionLogs,
                            targetLanguage: appState.targetLanguage,
                            lessonTopic: session.topic,
                            teacherName: session.teacherName,
                            teacherSchool: user.school,
                            teacherDesignation: user.designation,
                            teacherEmail: user.email,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Speech Notes (.txt) saved to Downloads:\n${file.path}'),
                                backgroundColor: Colors.brown.shade800,
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Download error: $e');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── DIALOGS ────────────────────────────────────────────────────────────────

  void _showEditProfileDialog(BuildContext context, AppState appState, UserModel user, bool isHindiUi) {
    final nameCtrl = TextEditingController(text: user.name);
    final schoolCtrl = TextEditingController(text: user.school);
    final desigCtrl = TextEditingController(text: user.designation);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isHindiUi ? 'शिक्षक प्रोफ़ाइल संपादित करें' : 'Edit Teacher Profile',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepCrimson),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: isHindiUi ? 'शिक्षक का नाम' : 'Teacher Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.person, color: AppTheme.deepCrimson),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: schoolCtrl,
                decoration: InputDecoration(
                  labelText: isHindiUi ? 'स्कूल का नाम' : 'School / Institution',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.school, color: AppTheme.deepCrimson),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: desigCtrl,
                decoration: InputDecoration(
                  labelText: isHindiUi ? 'पद / विषय' : 'Designation / Subject',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.badge, color: AppTheme.deepCrimson),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isHindiUi ? 'रद्द करें' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepCrimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newSchool = schoolCtrl.text.trim();
              final newDesig = desigCtrl.text.trim();
              if (newName.isNotEmpty && newSchool.isNotEmpty) {
                await appState.updateUserProfile(
                  name: newName,
                  school: newSchool,
                  designation: newDesig,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isHindiUi ? 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई!' : 'Profile updated successfully!'),
                      backgroundColor: Colors.green.shade800,
                    ),
                  );
                }
              }
            },
            child: Text(isHindiUi ? 'सहेजें' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showVoiceEnrollmentDialog(BuildContext context, AppState appState, bool isHindiUi) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => VoiceEnrollmentModal(
        appState: appState,
        isHindiUi: isHindiUi,
      ),
    );
  }

  void _showVoiceTestDialog(BuildContext context, AppState appState, bool isHindiUi) {
    showDialog(
      context: context,
      builder: (ctx) => VoiceTestModal(
        appState: appState,
        isHindiUi: isHindiUi,
      ),
    );
  }

  void _confirmDeleteVoice(BuildContext context, AppState appState, bool isHindiUi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isHindiUi ? 'आवाज़ प्रोफ़ाइल हटाएं?' : 'Delete Voice Profile?'),
        content: Text(
          isHindiUi
              ? 'क्या आप अपनी सहेजी गई आवाज़ प्रोफ़ाइल को हटाना चाहते हैं? आवाज़ मिलान फ़िल्टर निष्क्रिय हो जाएगा।'
              : 'Are you sure you want to delete your voice profile? 75% voice matching filter will be deactivated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isHindiUi ? 'रद्द करें' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await appState.deleteTeacherVoice();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(isHindiUi ? 'हटाएं' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AppState appState, bool isHindiUi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isHindiUi ? 'लॉग आउट करें?' : 'Sign Out?'),
        content: Text(
          isHindiUi
              ? 'क्या आप लॉग आउट करना चाहते हैं? आपका शिक्षण इतिहास डेटाबेस में सुरक्षित रहेगा।'
              : 'Are you sure you want to sign out? Your teaching history will remain safely stored in the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isHindiUi ? 'रद्द करें' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await appState.signOut();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(isHindiUi ? 'लॉग आउट' : 'Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ── INTERACTIVE 4-SENTENCE VOICE ENROLLMENT MODAL ─────────────────────────────

class VoiceEnrollmentModal extends StatefulWidget {
  final AppState appState;
  final bool isHindiUi;

  const VoiceEnrollmentModal({
    super.key,
    required this.appState,
    required this.isHindiUi,
  });

  @override
  State<VoiceEnrollmentModal> createState() => _VoiceEnrollmentModalState();
}

class _VoiceEnrollmentModalState extends State<VoiceEnrollmentModal>
    with SingleTickerProviderStateMixin {
  // ── Sentence list ─────────────────────────────────────────────────────────
  final List<String> _sentences = VoiceBiometricsEngine.enrollmentSentences;

  // ── Step tracking ─────────────────────────────────────────────────────────
  int _currentStep = 0;
  bool _isStepCompleted = false; // true only after sentence fully committed
  bool _isSaving = false;

  // ── Live transcript for current step ─────────────────────────────────────
  // Partials update this. It is NEVER used to auto-advance — only for display.
  String _livePartialText = '';

  // Buffer that accumulates final / committed recognized text for this step.
  // Only updated by onResultText (finalized) or by manual flush.
  String _committedText = '';

  // ── Collections saved across all 4 steps ─────────────────────────────────
  final List<String> _recordedSentences = [];
  final List<SpeechDeliveryMetrics> _recordedMetrics = [];

  // ── State flags for UI ────────────────────────────────────────────────────
  bool _isListening = false;
  bool _showSilenceWarning = false;

  // ── Delivery timing for current step ─────────────────────────────────────
  DateTime? _stepStartTime;      // when this step started listening
  DateTime? _firstSpeechTime;    // when first partial arrived
  DateTime? _lastSentenceEnd;    // when previous step was committed
  int _partialUpdateCount = 0;

  // ── Timers ────────────────────────────────────────────────────────────────
  // Silence-after-speech: fires 1.5s after the last partial update with ≥5 words
  Timer? _silenceCommitTimer;
  // If no speech at all for 5s → show warning prompt
  Timer? _noSpeechWarningTimer;
  // Brief pause before moving to next step (shows "✅ Verified" feedback)
  Timer? _advanceTimer;

  late AnimationController _pulseController;

  // ── Minimum word threshold to consider a sentence "substantially spoken" ──
  // We require at least 5 words before silence-commit fires.
  static const int _minWordsForCommit = 5;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Start ONE single continuous STT session for the entire enrollment.
    // We never stop/restart between sentences — only update which step we're on.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startContinuousStt());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // START ONE CONTINUOUS STT SESSION (called once in initState)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _startContinuousStt() async {
    if (!mounted) return;
    _stepStartTime = DateTime.now();
    _firstSpeechTime = null;
    _partialUpdateCount = 0;

    setState(() {
      _isListening = true;
      _showSilenceWarning = false;
    });

    _resetNoSpeechWarning();

    await widget.appState.speechService.startListening(
      localeId: 'hi_IN',

      // ── PARTIAL: update display only, drive silence-commit timer ──────────
      onPartialText: (partial) {
        if (!mounted || _isStepCompleted || _isSaving) return;

        final trimmed = partial.trim();
        if (trimmed.isEmpty) return;

        // Mark first speech time (for recognition lag metric)
        _firstSpeechTime ??= DateTime.now();
        _partialUpdateCount++;

        setState(() {
          _livePartialText = trimmed;
          _showSilenceWarning = false;
        });

        _resetNoSpeechWarning();

        // ── Silence-after-speech detection ─────────────────────────────────
        // Count words in what has been spoken so far (partial may grow).
        final wordCount = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

        if (wordCount >= _minWordsForCommit) {
          // Teacher has spoken enough words. If they pause for 1.5s, commit.
          _silenceCommitTimer?.cancel();
          _silenceCommitTimer = Timer(const Duration(milliseconds: 1500), () {
            if (!mounted || _isStepCompleted || _isSaving) return;
            // Use the partial as the recognized text (STT hasn't fired final yet)
            _commitCurrentStep(_livePartialText.isNotEmpty ? _livePartialText : trimmed);
          });
        }
      },

      // ── FINAL RESULT: also commits the step ───────────────────────────────
      // Chrome fires onResult (isFinal=true) after a longer natural pause.
      // When it fires AND we have ≥5 words, we commit immediately.
      onResultText: (text, _) {
        if (!mounted || _isStepCompleted || _isSaving) return;
        _silenceCommitTimer?.cancel(); // cancel pending silence-commit if final arrives first
        final trimmed = text.trim();
        if (trimmed.isEmpty) return;

        final wordCount = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        if (wordCount >= _minWordsForCommit) {
          _commitCurrentStep(trimmed);
        } else {
          // Not enough words yet — update display and wait
          setState(() => _livePartialText = trimmed);
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMMIT CURRENT STEP  (called by silence timer OR final STT result)
  // ─────────────────────────────────────────────────────────────────────────
  void _commitCurrentStep(String recognizedText) {
    if (_isStepCompleted || _isSaving) return;
    _silenceCommitTimer?.cancel();
    _noSpeechWarningTimer?.cancel();

    final now = DateTime.now();
    final stepStart = _stepStartTime ?? now;
    final firstSpeech = _firstSpeechTime ?? stepStart;

    final metrics = SpeechDeliveryMetrics(
      spokenText: recognizedText,
      durationMs: now.difference(stepStart).inMilliseconds.toDouble().clamp(200.0, 15000.0),
      partialUpdateCount: _partialUpdateCount.clamp(1, 30),
      partialToFinalMs: now.difference(firstSpeech).inMilliseconds.toDouble().clamp(100.0, 8000.0),
      interSentencePauseMs: _lastSentenceEnd != null
          ? stepStart.difference(_lastSentenceEnd!).inMilliseconds.toDouble().clamp(0.0, 6000.0)
          : 0.0,
    );

    _lastSentenceEnd = now;
    debugPrint('[VoiceEnrollment] Step ${_currentStep + 1} committed. metrics: $metrics');

    // Save recorded sentence + metrics
    if (_recordedSentences.length <= _currentStep) {
      _recordedSentences.add(recognizedText);
      _recordedMetrics.add(metrics);
    } else {
      _recordedSentences[_currentStep] = recognizedText;
      if (_recordedMetrics.length <= _currentStep) {
        _recordedMetrics.add(metrics);
      } else {
        _recordedMetrics[_currentStep] = metrics;
      }
    }

    setState(() {
      _isStepCompleted = true;
      _committedText = recognizedText;
      _showSilenceWarning = false;
    });

    // Show "✅ Verified" feedback for 1.2s then advance
    _advanceTimer = Timer(const Duration(milliseconds: 1200), _advanceToNextStep);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADVANCE TO NEXT STEP (or save if all 4 done)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _advanceToNextStep() async {
    if (!mounted) return;

    if (_currentStep < _sentences.length - 1) {
      // Move to next sentence — STT keeps running, just reset step state
      setState(() {
        _currentStep++;
        _isStepCompleted = false;
        _livePartialText = '';
        _committedText = '';
        _showSilenceWarning = false;
      });
      // Reset timing for new step
      _stepStartTime = DateTime.now();
      _firstSpeechTime = null;
      _partialUpdateCount = 0;
      _resetNoSpeechWarning();
    } else {
      // All 4 sentences done → save voiceprint
      setState(() {
        _isSaving = true;
        _isListening = false;
      });
      await widget.appState.speechService.stopListening();
      await _saveVoiceprint();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RETRY: reset current step without restarting STT
  // ─────────────────────────────────────────────────────────────────────────
  void _retryCurrentStep() {
    if (_isSaving) return;
    _silenceCommitTimer?.cancel();
    _advanceTimer?.cancel();

    // Remove this step's data if already recorded
    if (_recordedSentences.length > _currentStep) {
      _recordedSentences.removeRange(_currentStep, _recordedSentences.length);
    }
    if (_recordedMetrics.length > _currentStep) {
      _recordedMetrics.removeRange(_currentStep, _recordedMetrics.length);
    }

    setState(() {
      _isStepCompleted = false;
      _livePartialText = '';
      _committedText = '';
      _showSilenceWarning = false;
    });

    _stepStartTime = DateTime.now();
    _firstSpeechTime = null;
    _partialUpdateCount = 0;
    _resetNoSpeechWarning();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MANUAL "NEXT / SAVE" BUTTON
  // ─────────────────────────────────────────────────────────────────────────
  void _manualAdvance() {
    if (_isSaving) return;
    _silenceCommitTimer?.cancel();
    _advanceTimer?.cancel();

    // Use whatever text was captured (partial or committed)
    final text = _committedText.isNotEmpty
        ? _committedText
        : (_livePartialText.isNotEmpty ? _livePartialText : _sentences[_currentStep]);

    if (!_isStepCompleted) {
      _commitCurrentStep(text);
    } else {
      _advanceToNextStep();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NO-SPEECH WARNING TIMER  (5s silence → show prompt)
  // ─────────────────────────────────────────────────────────────────────────
  void _resetNoSpeechWarning() {
    _noSpeechWarningTimer?.cancel();
    if (mounted && _showSilenceWarning) {
      setState(() => _showSilenceWarning = false);
    }
    _noSpeechWarningTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isStepCompleted && !_isSaving) {
        setState(() => _showSilenceWarning = true);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SAVE VOICEPRINT TO SQLITE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _saveVoiceprint() async {
    try {
      final sentences = _recordedSentences.isNotEmpty ? _recordedSentences : _sentences;
      await widget.appState.enrollTeacherCompositeVoice(
        sentences,
        deliveryMetrics: _recordedMetrics,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isHindiUi
                  ? '🎉 आवाज़ प्रोफ़ाइल सफलतापूर्वक डेटाबेस में सहेजी गई! 75% फ़िल्टर सक्रिय।'
                  : '🎉 Voice Biometrics enrolled & saved! 75% Shield is now Active.',
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving voiceprint: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _silenceCommitTimer?.cancel();
    _noSpeechWarningTimer?.cancel();
    _advanceTimer?.cancel();
    _pulseController.dispose();
    widget.appState.speechService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.isHindiUi;
    final currentSentence = _sentences[_currentStep];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppTheme.cardWhite,
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.lightCream,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.record_voice_over, color: AppTheme.deepCrimson, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'आवाज़ प्रोफ़ाइल नामांकन' : 'Voice Biometrics Enrollment',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark),
                ),
                Text(
                  isHindi ? 'चरण ${_currentStep + 1} / 4 (उच्च सटीकता के लिए 4 वाक्य पढ़ें)' : 'Step ${_currentStep + 1} of 4 (Read 4 sentences)',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Step Progress Indicator Bubbles (1 -> 2 -> 3 -> 4)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  final isDone = index < _currentStep || (index == _currentStep && _isStepCompleted);
                  final isCurrent = index == _currentStep;

                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.green.shade700
                            : (isCurrent ? AppTheme.deepCrimson : AppTheme.lightCream),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDone
                              ? Colors.green
                              : (isCurrent ? AppTheme.deepCrimson : AppTheme.borderSubtle),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isDone)
                            const Icon(Icons.check_circle, color: Colors.white, size: 14)
                          else
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.white : AppTheme.textMuted,
                              ),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            'S${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDone || isCurrent ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // 2. Target Sentence To Read Out Loud
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isStepCompleted
                      ? Colors.green.shade50
                      : AppTheme.lightCream,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isStepCompleted ? Colors.green : AppTheme.borderSubtle,
                    width: _isStepCompleted ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isStepCompleted ? Icons.check_circle : Icons.volume_up,
                              size: 16,
                              color: _isStepCompleted ? Colors.green.shade800 : AppTheme.deepCrimson,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isHindi
                                  ? (_isStepCompleted ? '✅ वाक्य स्वीकृत' : 'कृपया स्पष्ट रूप से पढ़ें:')
                                  : (_isStepCompleted ? '✅ Sentence Verified' : 'Please read aloud:'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isStepCompleted ? Colors.green.shade800 : AppTheme.deepCrimson,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isStepCompleted ? Colors.green.shade700 : AppTheme.deepCrimson,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_currentStep + 1} / 4',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentSentence,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                        color: _isStepCompleted ? Colors.green.shade900 : AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Silence / Inactivity Watchdog Alert
              if (_showSilenceWarning)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isHindi
                              ? '⚠️ आवाज़ सुनाई नहीं दी। कृपया माइक्रोफ़ोन में स्पष्ट रूप से बोलें...'
                              : '⚠️ No speech detected yet. Please speak into your microphone...',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

              // 4. Live Microphone Waveform Visualizer & Recognition Transcript Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E0305),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isStepCompleted ? Colors.greenAccent : Colors.redAccent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isStepCompleted ? Colors.greenAccent : Colors.redAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _isStepCompleted ? Colors.greenAccent : Colors.redAccent,
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isSaving
                              ? (isHindi ? '24-D आवाज़ प्रोफाइल सहेजी जा रही है...' : 'Saving 24-D Voiceprint to SQLite...')
                              : (_isStepCompleted
                                  ? (isHindi ? 'वाक्य सत्यापित! अगले वाक्य पर बढ़ रहे हैं...' : 'Verified! Moving to next sentence...')
                                  : (isHindi ? 'माइक सुन रहा है... आप बोलें' : 'Listening... Speak now into Mic')),
                          style: TextStyle(
                            color: _isStepCompleted ? Colors.greenAccent : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Waveform Bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(9, (idx) {
                        return AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final cycle = (idx * 0.15 + _pulseController.value) % 1.0;
                            final height = _isListening
                                ? (6.0 + 18.0 * (0.5 + 0.5 * (cycle - 0.5).abs()))
                                : 5.0;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              width: 3.5,
                              height: height,
                              decoration: BoxDecoration(
                                color: _isStepCompleted
                                    ? Colors.greenAccent
                                    : Colors.redAccent.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isStepCompleted
                            ? (_committedText.isNotEmpty ? _committedText : _livePartialText)
                            : (_livePartialText.isNotEmpty
                                ? _livePartialText
                                : (isHindi ? '• आपकी आवाज़ यहाँ दिखाई देगी...' : '• Spoken words will appear here...')),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: (_isStepCompleted || _livePartialText.isNotEmpty) ? Colors.white : Colors.white54,
                          fontStyle: (_isStepCompleted || _livePartialText.isNotEmpty) ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Manual Controls: Retry or Next/Save
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.deepCrimson,
                        side: const BorderSide(color: AppTheme.deepCrimson),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.replay, size: 16),
                      label: Text(
                        isHindi ? 'पुनः बोलें' : 'Retry Sentence',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _retryCurrentStep,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepCrimson,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(
                        _currentStep < 3
                            ? (isHindi ? 'अगला वाक्य' : 'Next Sentence')
                            : (isHindi ? 'प्रोफ़ाइल सहेजें' : 'Save Voiceprint'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _manualAdvance,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.appState.speechService.stopListening();
            Navigator.of(context).pop();
          },
          child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
        ),
      ],
    );
  }
}

// ── INTERACTIVE LIVE VOICE TEST MODAL (75% THRESHOLD MATCHING) ────────────────

class VoiceTestModal extends StatefulWidget {
  final AppState appState;
  final bool isHindiUi;

  const VoiceTestModal({
    super.key,
    required this.appState,
    required this.isHindiUi,
  });

  @override
  State<VoiceTestModal> createState() => _VoiceTestModalState();
}

class _VoiceTestModalState extends State<VoiceTestModal> with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _liveSpokenText = '';
  VoiceMatchResult? _testResult;
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  Future<void> _toggleTesting() async {
    if (_isListening) {
      await widget.appState.speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _liveSpokenText = '';
        _testResult = null;
      });

      await widget.appState.speechService.startListening(
        localeId: 'hi_IN',
        onResultText: (text, metrics) {
          if (!mounted) return;
          final result = widget.appState.testVoiceMatch(text, deliveryMetrics: metrics);
          setState(() {
            _liveSpokenText = text;
            _testResult = result;
          });
        },
        onPartialText: (partial) {
          if (!mounted) return;
          final result = widget.appState.testVoiceMatch(partial);
          setState(() {
            _liveSpokenText = partial;
            _testResult = result;
          });
        },
      );
    }
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    if (_isListening) {
      widget.appState.speechService.stopListening();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.isHindiUi;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isHindi ? 'आवाज़ मिलान परीक्षण (75% फ़िल्टर)' : 'Test Voice Matcher (75% Threshold)',
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.deepCrimson, fontSize: 17),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isHindi
                  ? 'माइक में कोई भी वाक्य बोलें। 75% से अधिक मिलान होने पर ही कक्षा में आवाज़ अनुवादित होगी:'
                  : 'Speak any sentence into the microphone to verify that your voice passes the 75% threshold filter:',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red.shade800 : AppTheme.deepCrimson,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(_isListening ? Icons.stop_circle : Icons.mic),
              label: Text(
                _isListening
                    ? (isHindi ? 'माइक बंद करें' : 'Stop Listening')
                    : (isHindi ? 'माइक में बोलकर परीक्षण करें' : 'Speak into Mic to Test'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: _toggleTesting,
            ),
            if (_liveSpokenText.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightCream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(
                  'Spoken: "$_liveSpokenText"',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textDark),
                ),
              ),
            ],
            if (_testResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _testResult!.isMatched ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _testResult!.isMatched ? Colors.green : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _testResult!.isMatched ? Icons.check_circle : Icons.cancel,
                          color: _testResult!.isMatched ? Colors.green.shade800 : Colors.red.shade800,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Match Score: ${(_testResult!.similarityScore * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _testResult!.isMatched ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _testResult!.isMatched
                          ? (isHindi
                              ? '✅ शिक्षक आवाज़ सत्यापित (75% से अधिक) - कक्षा माइक चालू रहेगा'
                              : '✅ Verified Teacher Voice (>= 75%) - Classroom Mic Passes')
                          : (isHindi
                              ? '⛔ पृष्ठभूमि आवाज़ फ़िल्टर की गई (< 75%) - कक्षा बाधित नहीं होगी'
                              : '⛔ Background Voice Filtered (< 75%) - Classroom Suppressed'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _testResult!.isMatched ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_isListening) widget.appState.speechService.stopListening();
            Navigator.of(context).pop();
          },
          child: Text(isHindi ? 'बंद करें' : 'Close'),
        ),
      ],
    );
  }
}
