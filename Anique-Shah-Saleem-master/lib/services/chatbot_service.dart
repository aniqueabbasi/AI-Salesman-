import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ChatProduct {
  final String id;
  final String title;
  final String brand;
  final double price;
  final double? discountPercentage;
  final String? imageUrl;

  ChatProduct({
    required this.id,
    required this.title,
    required this.brand,
    required this.price,
    this.discountPercentage,
    this.imageUrl,
  });

  factory ChatProduct.fromJson(Map<String, dynamic> json) {
    return ChatProduct(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? json['name'] ?? '',
      brand: json['brand'] ?? '',
      price: (json['selling_price'] ?? json['price'] ?? 0).toDouble(),
      discountPercentage:
          (json['discount_percentage'] ?? json['discount'])?.toDouble(),
      imageUrl: json['image_url'] ?? json['imageUrl'] ??
          ((json['images'] is List && (json['images'] as List).isNotEmpty) ? (json['images'] as List).first : null),
    );
  }
}

class ChatbotMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<ChatProduct>? products;
  final bool hasMore;
  final String? showMorePrompt;

  ChatbotMessage({
    required this.text,
    required this.isUser,
    this.products,
    this.hasMore = false,
    this.showMorePrompt,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatbotService {
  static final List<ChatbotMessage> _messageHistory = [];
  static String get _fastApiUrl => ApiConfig.chatbotBaseUrl;
  // Try .env BASE_URL else default to localhost:8001

  // Get all messages in the history
  static List<ChatbotMessage> getMessages() {
    return _messageHistory;
  }

  static Future<void> initialize() async {
    try {
      debugPrint('🔍 Initializing chatbot service');

      // Add a welcome message to the history
      _messageHistory.add(ChatbotMessage(
        text:
            "Hi! I'm your shopping assistant. How can I help you today with finding clothes, checking sizes, or anything else?",
        isUser: false,
      ));

      debugPrint('✅ Chatbot service initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Error initializing chatbot service: $e');
    }
  }

  static Future<ChatbotMessage> sendMessage(String message,
      {int page = 1}) async {
    // Store user message locally so that it appears instantly in UI
    _messageHistory.add(ChatbotMessage(text: message, isUser: true));

    try {
      debugPrint('📤 Sending message to API: "$message" (page: $page)');

      final response = await http.post(
        Uri.parse('$_fastApiUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'page': page,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Full chatbot response: \\${response.body}');
        // Parse main bot text (FastAPI returns it in "message")
        final String botText = data['message'] ?? data['response_text'] ?? '';

        // Parse products if present
        List<ChatProduct>? products;
        if (data['products'] != null && data['products'] is List) {
          products = (data['products'] as List)
              .map((e) => ChatProduct.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        final bool hasMore = data['has_more'] ?? false;
        final String? showMorePrompt = data['show_more_prompt'] ??
            data['pagination_context']?['show_more_prompt'];

        return _createAndStoreResponse(
          text: botText,
          products: products,
          hasMore: hasMore,
          showMorePrompt: showMorePrompt,
        );
      }

      // If FastAPI returns non-200
      debugPrint(
          '⚠️ FastAPI responded with status ${response.statusCode}: ${response.body}');
      return _createAndStoreResponse(text: _getSmartResponse(message));
    } catch (e) {
      debugPrint('⚠️ Error calling FastAPI: $e');
      return _createAndStoreResponse(text: _getSmartResponse(message));
    }
  }

  // Helper method to create and store bot response
  static ChatbotMessage _createAndStoreResponse({
    required String text,
    List<ChatProduct>? products,
    bool hasMore = false,
    String? showMorePrompt,
  }) {
    final botResponse = ChatbotMessage(
      text: text,
      isUser: false,
      products: products,
      hasMore: hasMore,
      showMorePrompt: showMorePrompt,
    );
    _messageHistory.add(botResponse);
    return botResponse;
  }

  // Provides smart responses based on keywords and context (used as fallback)
  static String _getSmartResponse(String message) {
    final lowerMessage = message.toLowerCase();

    // Greeting detection
    if (_containsAny(lowerMessage, ['hello', 'hi', 'hey', 'greetings', 'yo'])) {
      return "Hello! I'm happy to help with your shopping today. Are you looking for something specific?";
    }

    // Size guidance
    if (_containsAny(lowerMessage,
        ['size', 'fit', 'measurement', 'large', 'small', 'medium'])) {
      return "For clothing sizes, our size guide recommends measuring yourself and comparing to our chart. Generally, if you're between sizes, going one size up is better for comfort. Would you like me to tell you how to measure for a specific item?";
    }

    // Return policy
    if (_containsAny(
        lowerMessage, ['return', 'refund', 'exchange', 'money back'])) {
      return "We offer a hassle-free 30-day return policy for unworn items with original tags attached. Refunds are processed within 5-7 business days to your original payment method. Would you like more information about our exchange process?";
    }

    // Shipping info
    if (_containsAny(
        lowerMessage, ['shipping', 'delivery', 'arrive', 'ship', 'tracking'])) {
      return "Standard shipping takes 3-5 business days. Express shipping (1-2 days) is available for an additional fee. We offer free standard shipping on orders over \$50. Once your order ships, you'll receive tracking information via email.";
    }

    // Payment methods
    if (_containsAny(
        lowerMessage, ['payment', 'pay', 'credit card', 'debit', 'paypal'])) {
      return "We accept all major credit cards (Visa, MasterCard, American Express), PayPal, and Apple Pay for your convenience. All transactions are secure and encrypted.";
    }

    // Discounts and promos
    if (_containsAny(lowerMessage,
        ['discount', 'coupon', 'sale', 'promo', 'offer', 'deal'])) {
      return "Subscribe to our newsletter to receive a 10% discount on your first order. We also run seasonal sales throughout the year. Currently, we have a buy-one-get-one 50% off deal on selected items. Would you like to know which items are on sale?";
    }

    // Default response
    return "I'm here to help with your shopping needs. You can ask me about products, sizes, shipping, returns, or any other shopping-related questions.";
  }

  // Helper method to check if a message contains any of the given keywords
  static bool _containsAny(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }
}
