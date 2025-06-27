import 'package:flutter/material.dart';
import 'package:tenorwisp/thread_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class PublicThreadsScreen extends StatelessWidget {
  const PublicThreadsScreen({super.key});

  // Placeholder data for the demo
  static final List<Map<String, dynamic>> _dummyThreads = [
    {
      'title': 'How will AI impact creativity and the arts?',
      'generatedAt': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'title':
          'What is the future of remote work and its effect on urban living?',
      'generatedAt': DateTime.now().subtract(const Duration(hours: 18)),
    },
    {
      'title':
          'How can we foster more meaningful social connections in a digital age?',
      'generatedAt': DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussions'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView.builder(
        itemCount: _dummyThreads.length,
        itemBuilder: (context, index) {
          final thread = _dummyThreads[index];
          final title = thread['title'] as String;
          final timestamp = thread['generatedAt'] as DateTime;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(title),
              subtitle: Text('Posted ${timeago.format(timestamp)}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ThreadDetailScreen(threadTitle: title),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
