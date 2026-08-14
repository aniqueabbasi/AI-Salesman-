import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // Store verification codes with email as key
  final Map<String, String> _verificationCodes = {};

  // Generate a random 6-digit verification code
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send verification email
  Future<bool> sendVerificationEmail(String email) async {
    try {
      final username = dotenv.get('EMAIL_USER');
      final password = dotenv.get('EMAIL_PASSWORD');
      
      developer.log('Attempting to send email to $email', name: 'EmailService');
      
      // Generate a new verification code
      final verificationCode = _generateVerificationCode();
      
      // Store the code with the email
      _verificationCodes[email] = verificationCode;
      
      // Email content
      final message = Message()
        ..from = Address(username, 'Your App Name')
        ..recipients.add(email)
        ..subject = 'Email Verification Code'
        ..text = 'Your verification code is: $verificationCode\n\nThis code will expire in 10 minutes.'
        ..html = """
          <h2>Email Verification</h2>
          <p>Your verification code is: <strong>$verificationCode</strong></p>
          <p>This code will expire in 10 minutes.</p>
          <p>If you didn't request this, please ignore this email.</p>
        """;

      // Create SMTP server with explicit settings
      final smtpServer = gmail(
        username,
        password,
      );
      
      // Add timeout
      const sendTimeout = Duration(seconds: 30);
      
      developer.log('Sending verification email to $email', name: 'EmailService');
      
      // Send the email with a timeout
      final sendReport = await send(message, smtpServer)
          .timeout(sendTimeout, onTimeout: () {
            throw TimeoutException('Email sending timed out after ${sendTimeout.inSeconds} seconds');
          });
      
      developer.log('Email sent: ${sendReport.toString()}', name: 'EmailService');
      
      // Set a timer to remove the code after 10 minutes
      Future.delayed(const Duration(minutes: 10), () {
        if (_verificationCodes[email] == verificationCode) {
          _verificationCodes.remove(email);
        }
      });

      return true;
    } on TimeoutException catch (e) {
      developer.log('Email sending timed out: $e', name: 'EmailService', error: e);
      return false;
    } on MailerException catch (e) {
      developer.log('Mailer error: ${e.message}', name: 'EmailService', error: e);
      if (e.toString().contains('Bad credentials')) {
        developer.log('Invalid email credentials. Please check your email and app password.', 
            name: 'EmailService');
      }
      return false;
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'EmailService', error: e);
      return false;
    }
  }

  // Verify the code
  bool verifyCode(String email, String code) {
    developer.log('Verifying code for $email', name: 'EmailService');
    final storedCode = _verificationCodes[email];
    if (storedCode == null || storedCode != code) {
      developer.log('Invalid code for $email. Stored: $storedCode, Provided: $code', 
          name: 'EmailService');
      return false;
    }
    // Remove the code after successful verification
    _verificationCodes.remove(email);
    developer.log('Code verified successfully for $email', name: 'EmailService');
    return true;
  }
}
