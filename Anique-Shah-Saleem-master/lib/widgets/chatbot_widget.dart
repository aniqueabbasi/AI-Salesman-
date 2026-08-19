import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../AppScreens/ProductDetailPage.dart';
import '../Controller/ChatbotProvider.dart';
import '../config/api_config.dart';
import '../models/Product.dart';
import '../res/app_theme.dart';
import '../res/ui_kit.dart';
import '../services/chatbot_service.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({Key? key}) : super(key: key);

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
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

  /// The assistant service this widget is talking to, e.g. `:8001`.
  String get _endpointLabel {
    final port = Uri.tryParse(ApiConfig.chatbotBaseUrl)?.port;
    return port == null ? 'assistant' : 'assistant · :$port';
  }

  void _send(ChatbotProvider provider) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    provider.sendMessage(text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatbotProvider = Provider.of<ChatbotProvider>(context);

    // Scroll to bottom when new messages are added
    if (chatbotProvider.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(chatbotProvider),
          Expanded(
            child: chatbotProvider.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                    itemCount: chatbotProvider.messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(chatbotProvider.messages[index]),
                  ),
          ),
          if (chatbotProvider.isLoading) _buildThinking(),
          _buildComposer(chatbotProvider),
        ],
      ),
    );
  }

  Widget _buildHeader(ChatbotProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: const BoxDecoration(
        color: AppTheme.darkBg,
        border: Border(bottom: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('AI',
                style: AppTheme.mono(12, color: Colors.white, tracking: 0.04)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Shopping assistant',
                    style: AppTheme.ui(15,
                        color: AppTheme.darkTextBright,
                        weight: FontWeight.w600,
                        height: 1.1)),
                const SizedBox(height: 2),
                Text(_endpointLabel,
                    style: AppTheme.mono(10, color: AppTheme.darkTextMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: provider.toggleChat,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close,
                  size: 20, color: AppTheme.darkTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          "Ask me for anything in the catalogue — a colour, a budget, a size.",
          textAlign: TextAlign.center,
          style: AppTheme.ui(14, color: AppTheme.darkTextMuted, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildThinking() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
            ),
          ),
          const SizedBox(width: 10),
          Text('Thinking…',
              style: AppTheme.mono(11, color: AppTheme.darkTextMuted)),
        ],
      ),
    );
  }

  Widget _buildComposer(ChatbotProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: AppTheme.darkBg,
        border: Border(top: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceAlt,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _messageController,
                style: AppTheme.ui(14, color: AppTheme.darkTextPrimary),
                cursorColor: AppTheme.accent,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Ask about any product…',
                  hintStyle:
                      AppTheme.ui(14, color: AppTheme.darkTextMuted),
                ),
                onSubmitted: (_) => _send(provider),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(provider),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatbotMessage message) {
    final isBot = !message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.62,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isBot ? AppTheme.darkSurface : AppTheme.accent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              message.text,
              style: AppTheme.ui(
                14,
                color: isBot ? AppTheme.darkTextPrimary : Colors.white,
                height: 1.45,
              ),
            ),
          ),
          if (isBot && message.products != null && message.products!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: message.products!
                    .map((p) => _ChatProductCard(product: p))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact dark product card rendered underneath an assistant reply.
class _ChatProductCard extends StatelessWidget {
  final ChatProduct product;

  const _ChatProductCard({required this.product});

  /// The assistant returns its own product shape; map it onto the app's model
  /// so tapping through opens the normal detail page.
  Product get _asProduct => Product(
        id: product.id,
        name: product.title,
        description: product.brand,
        price: product.price,
        images: product.imageUrl != null ? [product.imageUrl!] : [],
        category: 'General',
        originalPrice: product.discountPercentage != null
            ? product.price * 100 / (100 - product.discountPercentage!)
            : null,
        discount: product.discountPercentage?.round() ?? 0,
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: _asProduct)),
      ),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: SizedBox(
                width: double.infinity,
                height: 84,
                child: _buildImage(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.ui(12,
                  color: AppTheme.darkTextPrimary,
                  weight: FontWeight.w500,
                  height: 1.25),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatPkr(product.price),
                    style: AppTheme.display(14, color: AppTheme.darkTextBright),
                  ),
                ),
                if (product.discountPercentage != null)
                  Text(
                    '-${product.discountPercentage!.round()}%',
                    style: AppTheme.mono(10, color: AppTheme.accent),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = product.imageUrl;
    Widget placeholder() => Container(
          color: AppTheme.darkSurfaceAlt,
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined,
              size: 22, color: AppTheme.darkTextMuted),
        );

    if (url == null || url.isEmpty) return placeholder();

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder(),
      errorBuilder: (_, __, ___) => placeholder(),
    );
  }
}
