import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';

class ChatbotProvider extends ChangeNotifier {
  List<ChatbotMessage> _messages = [];
  bool _isLoading = false;
  bool _isChatOpen = false;

  List<ChatbotMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isChatOpen => _isChatOpen;
  
  // Constructor with immediate synchronous load and future async load
  ChatbotProvider() {
    _loadExistingMessages();
    // Also try to load asynchronously to ensure we have the latest messages
    Future.microtask(() async {
      await _loadExistingMessagesAsync();
    });
  }
  
  // Synchronous message loading - for immediate UI init
  void _loadExistingMessages() {
    try {
      final serviceMessages = ChatbotService.getMessages();
      if (serviceMessages.isNotEmpty) {
        _messages = List.from(serviceMessages);
      }
    } catch (e) {
      debugPrint('Error loading existing messages: $e');
    }
  }
  
  // Async version that can be awaited
  Future<void> _loadExistingMessagesAsync() async {
    try {
      final serviceMessages = ChatbotService.getMessages();
      if (serviceMessages.isNotEmpty && (serviceMessages.length != _messages.length)) {
        _messages = List.from(serviceMessages);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading existing messages asynchronously: $e');
    }
  }

  void toggleChat() {
    _isChatOpen = !_isChatOpen;
    notifyListeners();
  }

  void openChat() {
    _isChatOpen = true;
    notifyListeners();
  }

  void closeChat() {
    _isChatOpen = false;
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // We don't need to add the user message since the ChatbotService will handle it
    _isLoading = true;
    notifyListeners();

    try {
      // Get response from chatbot service
      await ChatbotService.sendMessage(message);
      
      // Update the messages list from the service to ensure consistency
      _messages = List.from(ChatbotService.getMessages());
    } catch (e) {
      // Add error message if something goes wrong
      _messages.add(ChatbotMessage(
        text: 'Sorry, something went wrong. Please try again later.',
        isUser: false,
      ));
      debugPrint('Error sending message: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
} 