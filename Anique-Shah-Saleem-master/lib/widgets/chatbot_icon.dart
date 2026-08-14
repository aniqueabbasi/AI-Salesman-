import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/ChatbotProvider.dart';
import 'chatbot_widget.dart';

class ChatbotIcon extends StatelessWidget {
  const ChatbotIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatbotProvider = Provider.of<ChatbotProvider>(context);

    return Stack(
      children: [
        Positioned(
          bottom: 16,
          right: 16,
          child: chatbotProvider.isChatOpen
              ? Container(
                  alignment: Alignment.bottomRight,
                  child: const ChatbotWidget(),
                )
              : FloatingActionButton(
                  onPressed: () => chatbotProvider.openChat(),
                  backgroundColor: Colors.lightBlue,
                  child: const Icon(Icons.support_agent, color: Colors.white),
                ),
        ),
      ],
    );
  }
} 