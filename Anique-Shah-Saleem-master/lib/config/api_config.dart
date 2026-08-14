import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // For security reasons, you should not hardcode your API key here in production
  // Instead, use environment variables, secure storage, or another secure approach
  // This is just for demonstration purposes
  static const String geminiApiKey = "YOUR_GEMINI_API_KEY";

  /// An Android emulator reaches the host machine on 10.0.2.2 rather than
  /// localhost; every other target (iOS simulator, desktop, web) uses 127.0.0.1.
  static String get _host =>
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? '10.0.2.2'
          : '127.0.0.1';

  /// Reads an override from .env when present, otherwise falls back to the
  /// local server on [port]. Keeping these in .env means the URLs can change
  /// (ngrok, a LAN IP, a deployed host) without editing Dart code.
  static String _url(String envKey, int port) {
    if (dotenv.isInitialized) {
      final value = dotenv.env[envKey];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return 'http://$_host:$port';
  }

  // Main API for auth and data (ecom_FYP-main, port 8000)
  static String get mainBaseUrl => _url('BASE_URL', 8000);

  // Chatbot API (testEcomChatbot, port 8001)
  static String get chatbotBaseUrl => _url('CHATBOT_URL', 8001);

  // Recommendation API (recommendation system, port 8002)
  static String get recommendationBaseUrl => _url('RECOMMENDATION_URL', 8002);
}
