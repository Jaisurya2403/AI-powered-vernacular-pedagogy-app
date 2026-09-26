import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vernacular_pedagogy/models/app_models.dart';
import 'package:vernacular_pedagogy/services/db_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Teacher Profile, Persistent Auth & Teaching History Tests', () {
    test('Persists and clears active user session across restarts', () async {
      const email = 'teacher.test@school.edu';

      await DbHelper.setActiveUserSession(email);
      String? activeEmail = await DbHelper.getActiveUserSession();
      expect(activeEmail, email);

      await DbHelper.clearActiveUserSession();
      activeEmail = await DbHelper.getActiveUserSession();
      expect(activeEmail, null);
    });

    test('Registers user and updates teacher profile info', () async {
      final userId = await DbHelper.registerUser(
        name: 'Sunita Sharma',
        email: 'sunita.teacher@gov.in',
        password: 'Password@123',
        school: 'Primary School Dumka',
        designation: 'Mathematics Teacher',
      );

      expect(userId > 0, true);

      // Update Profile
      final updated = await DbHelper.updateUserProfile(
        userId: userId,
        name: 'Dr. Sunita Sharma',
        school: 'Kendriya Vidyalaya Dumka',
        designation: 'Senior Vernacular Educator',
      );

      expect(updated, true);

      final userMap = await DbHelper.getUserByEmail('sunita.teacher@gov.in');
      expect(userMap!['name'], 'Dr. Sunita Sharma');
      expect(userMap['school'], 'Kendriya Vidyalaya Dumka');
    });

    test('Saves and retrieves teaching sessions history with date-wise notes metadata', () async {
      final session = TeachingSessionModel(
        userId: 101,
        topic: 'Mathematics - Subtraction in Ol Chiki',
        teacherName: 'Sunita Sharma',
        targetLanguage: 'Santhali (ᱥᱟᱱᱛᱟᱲᱤ)',
        dateStr: '25/09/2026',
        timeStr: '10:30',
        totalSentences: 12,
        notesFilePath: '/storage/emulated/0/Download/session_notes_101.txt',
        docxFilePath: '/storage/emulated/0/Download/study_material_101.docx',
      );

      final sessionId = await DbHelper.saveTeachingSession(session);
      expect(sessionId > 0, true);

      final history = await DbHelper.fetchTeachingSessionsForUser(101);
      expect(history.isNotEmpty, true);
      expect(history.first.topic, 'Mathematics - Subtraction in Ol Chiki');
      expect(history.first.totalSentences, 12);
      expect(history.first.dateStr, '25/09/2026');
    });

    test('Saves, retrieves, and deletes voiceprint biometric vector in SQLite', () async {
      final vp = VoiceprintModel(
        userId: 202,
        embedding: '[0.12, 0.45, 0.78, 0.99, 0.34]',
        sampleCount: 1,
        promptText: 'नमस्ते बच्चों',
      );

      await DbHelper.saveVoiceprint(vp);

      final retrieved = await DbHelper.getVoiceprintForUser(202);
      expect(retrieved != null, true);
      expect(retrieved!.embedding.contains('0.12'), true);

      await DbHelper.deleteVoiceprint(202);
      final afterDelete = await DbHelper.getVoiceprintForUser(202);
      expect(afterDelete, null);
    });
  });
}
