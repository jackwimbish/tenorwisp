import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tenorwisp/thread_detail_screen.dart';

class PublicThreadsScreen extends StatelessWidget {
  const PublicThreadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Discussions")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('public_threads')
            .orderBy('generatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong."));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No discussions have started yet.\nCheck back soon!",
                textAlign: TextAlign.center,
              ),
            );
          }

          final threads = snapshot.data!.docs;

          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final threadData = threads[index].data() as Map<String, dynamic>;
              final threadId = threads[index].id;
              final timestamp = (threadData['generatedAt'] as Timestamp?)
                  ?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(threadData['title'] ?? 'Untitled Thread'),
                  subtitle: Text(
                    'Generated on: ${timestamp?.toString() ?? '...'}',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ThreadDetailScreen(threadId: threadId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
