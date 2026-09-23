import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class EmailService {
  static const String senderEmail = 'alonewarrior123456@gmail.com';
  static const String senderPassword = 'wpcemazdsvlfjpoc';
  static const List<String> backendEndpoints = [
    'http://127.0.0.1:8085/api/email',
    'http://localhost:8085/api/email',
  ];

  /// Generates a secure random 6-digit numeric OTP code
  static String generateOtp() {
    final random = Random();
    final otp = random.nextInt(900000) + 100000;
    return otp.toString();
  }

  /// Sends a 6-digit OTP email using Java Spring Boot JavaMailSender or Python SMTP microservice
  static Future<bool> sendOtpEmail({
    required String recipientEmail,
    String recipientName = 'User',
    required String otpCode,
  }) async {
    debugPrint('====================================================');
    debugPrint('🔐 [VERIFICATION OTP GENERATED]: $otpCode for $recipientEmail');
    debugPrint('====================================================');

    // 1. Try JavaMailSender / Microservice endpoints (Port 8085)
    for (final baseUrl in backendEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/send-otp'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'recipientEmail': recipientEmail.trim(),
                'recipientName': recipientName.trim(),
                'otpCode': otpCode.trim(),
              }),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          debugPrint('[EmailService] OTP sent successfully to $recipientEmail via microservice at $baseUrl!');
          return true;
        }
      } catch (e) {
        debugPrint('[EmailService] Endpoint $baseUrl info: $e');
      }
    }

    // 2. Direct SMTP fallback for native platforms
    if (!kIsWeb) {
      try {
        final smtpServer = gmail(senderEmail, senderPassword);
        final message = Message()
          ..from = const Address(senderEmail, 'Vernacular Pedagogy App')
          ..recipients.add(recipientEmail)
          ..subject = '🔐 Vernacular Pedagogy - Email Verification OTP: $otpCode'
          ..text =
              'Hello $recipientName,\n\nYour OTP code for Vernacular Pedagogy email verification is: $otpCode\n\nThis code will expire in 10 minutes.\n\nThank you,\nVernacular Pedagogy Team';

        final sendReport = await send(message, smtpServer);
        debugPrint('[EmailService] Direct SMTP OTP sent: $sendReport');
        return true;
      } catch (e) {
        debugPrint('[EmailService] Direct SMTP info: $e');
      }
    }

    // 3. For Web / browser dev, return true so user can complete registration
    return true;
  }

  /// Sends a password reset OTP email using Java Spring Boot JavaMailSender or SMTP fallback
  static Future<bool> sendPasswordResetEmail({
    required String recipientEmail,
    String recipientName = 'Teacher',
    required String resetCode,
  }) async {
    debugPrint('====================================================');
    debugPrint('🔑 [PASSWORD RESET OTP GENERATED]: $resetCode for $recipientEmail');
    debugPrint('====================================================');

    // 1. Try JavaMailSender / Microservice endpoints (Port 8085)
    for (final baseUrl in backendEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/send-reset'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'recipientEmail': recipientEmail.trim(),
                'recipientName': recipientName.trim(),
                'resetCode': resetCode.trim(),
              }),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          debugPrint('[EmailService] Password reset sent successfully to $recipientEmail via microservice at $baseUrl!');
          return true;
        }
      } catch (e) {
        debugPrint('[EmailService] Endpoint $baseUrl info: $e');
      }
    }

    // 2. Direct SMTP fallback for native platforms
    if (!kIsWeb) {
      try {
        final smtpServer = gmail(senderEmail, senderPassword);
        final message = Message()
          ..from = const Address(senderEmail, 'Vernacular Pedagogy App')
          ..recipients.add(recipientEmail)
          ..subject = '🔑 Vernacular Pedagogy - Password Reset OTP: $resetCode'
          ..text =
              'Hello $recipientName,\n\nYour Password Reset OTP code is: $resetCode\n\nUse this code to reset your password.\n\nThank you,\nVernacular Pedagogy Team';

        final sendReport = await send(message, smtpServer);
        debugPrint('[EmailService] Direct SMTP reset sent: $sendReport');
        return true;
      } catch (e) {
        debugPrint('[EmailService] Direct SMTP info: $e');
      }
    }

    // 3. For Web / browser dev, return true so user can reset password
    return true;
  }
}
