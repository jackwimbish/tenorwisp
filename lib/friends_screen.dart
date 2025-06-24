import 'package:flutter/material.dart';
import 'add_friend_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Friends'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // My Friends List
            Center(child: Text('Your friends will appear here.')),
            // Friend Requests List
            Center(child: Text('Friend requests will appear here.')),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddFriendScreen()));
          },
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }
}
