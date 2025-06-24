import 'package:flutter/material.dart';

class AddFriendScreen extends StatelessWidget {
  const AddFriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Friend')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search field
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Search by username or email',
                suffixIcon: Icon(Icons.search),
              ),
              onFieldSubmitted: (value) {
                // TODO: Implement search logic
              },
            ),
            const SizedBox(height: 20),
            // Search results area
            Expanded(
              child: Center(child: Text('Search results will appear here.')),
            ),
          ],
        ),
      ),
    );
  }
}
