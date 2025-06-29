import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tenorwisp/service_locator.dart';
import 'package:tenorwisp/services/chat_service.dart';
import 'package:tenorwisp/services/user_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  late final UserService _userService;
  late final ChatService _chatService;

  final Map<String, bool> _selectedFriends = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userService = getIt<UserService>();
    _chatService = getIt<ChatService>();
  }

  void _onFriendSelected(String friendId, bool? isSelected) {
    setState(() {
      _selectedFriends[friendId] = isSelected ?? false;
    });
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name.')),
      );
      return;
    }

    final selectedFriendIds = _selectedFriends.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one friend.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _chatService.createGroupChat(groupName, selectedFriendIds);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton(
              onPressed: _isLoading ? null : _createGroup,
              child: const Text('CREATE'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildFriendsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userService.getUserDocStream(_userService.currentUser!.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!userSnapshot.hasData || userSnapshot.hasError) {
          return const Center(child: Text('Could not load your friends.'));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final friendIds = (userData?['friends'] as List?)?.cast<String>() ?? [];

        if (friendIds.isEmpty) {
          return const Center(
            child: Text('You have no friends to add to a group.'),
          );
        }

        return StreamBuilder<List<DocumentSnapshot>>(
          stream: _userService.getUsersStream(friendIds),
          builder: (context, friendsSnapshot) {
            if (friendsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!friendsSnapshot.hasData || friendsSnapshot.hasError) {
              return const Center(child: Text('Could not load friends.'));
            }

            final friends = friendsSnapshot.data!;

            return ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friendDoc = friends[index];
                final friendData = friendDoc.data() as Map<String, dynamic>;
                final friendId = friendDoc.id;

                return CheckboxListTile(
                  title: Text(friendData['username'] ?? 'No Name'),
                  value: _selectedFriends[friendId] ?? false,
                  onChanged: (bool? value) {
                    _onFriendSelected(friendId, value);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
