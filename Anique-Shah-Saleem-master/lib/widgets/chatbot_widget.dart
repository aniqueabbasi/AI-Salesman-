import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/ChatbotProvider.dart';
import '../services/chatbot_service.dart';
import '../models/Product.dart';
import '../AppScreens/ProductDetailPage.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({Key? key}) : super(key: key);

  @override
  _ChatbotWidgetState createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatbotProvider = Provider.of<ChatbotProvider>(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // Scroll to bottom when new messages are added
    if (chatbotProvider.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.lightBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.support_agent, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Shopping Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chat messages with keyboard-aware scrolling
          Expanded(
            child: Column(
              children: [
                // Messages container with flexible height
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: chatbotProvider.messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Hi! I\'m your shopping assistant. How can I help you today?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: chatbotProvider.messages.length,
                            itemBuilder: (context, index) {
                              final message = chatbotProvider.messages[index];
                              return _buildMessageBubble(message);
                            },
                          ),
                  ),
                ),
                // Add some space when keyboard is visible
                if (keyboardHeight > 0) SizedBox(height: keyboardHeight * 0.5),
              ],
            ),
          ),
          // Loading indicator
          if (chatbotProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text("Thinking...", style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        chatbotProvider.sendMessage(value);
                        _messageController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      chatbotProvider.sendMessage(_messageController.text);
                      _messageController.clear();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatbotMessage message) {
    final isBot = !message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment:
            isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment:
                message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isBot)
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.lightBlue.shade100,
                  child: const Icon(Icons.support_agent, size: 15, color: Colors.blue),
                ),
              const SizedBox(width: 5),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.55,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isUser ? Colors.blue.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(message.text),
              ),
              const SizedBox(width: 5),
              if (message.isUser)
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, size: 15, color: Colors.white),
                ),
            ],
          ),
          if (isBot && message.products != null && message.products!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 40.0, right: 8.0),
              child: Column(
                children: message.products!.map((product) => _buildProductCard(product)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ChatProduct product) {
    // Create a Product object from ChatProduct
    final productModel = Product(
      id: product.id,
      name: product.title,
      description: product.brand,
      price: product.price,
      images: product.imageUrl != null ? [product.imageUrl!] : [],
      category: 'General', // Default category
      originalPrice: product.discountPercentage != null 
          ? product.price * 100 / (100 - product.discountPercentage!) 
          : null,
      discount: product.discountPercentage?.round() ?? 0,
    );
    
    // Get the first image URL or use a placeholder
    final imageUrl = product.imageUrl;

    return GestureDetector(
      onTap: () {
        // Navigate to product detail page with the product model
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: productModel),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (product.brand.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(product.brand, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('PKR ${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                    if (product.discountPercentage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text('Discount: ${product.discountPercentage!.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}