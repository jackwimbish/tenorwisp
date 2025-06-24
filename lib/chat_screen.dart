import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  // We will need to pass arguments here later, like the chat ID or recipient's UID.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'), // This will later show the recipient's name
      ),
      body: Column(
        children: [
          const Expanded(
            child: Center(child: Text('Messages will appear here.')),
          ),
          // Placeholder for the message input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // TODO: Implement send message logic
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
