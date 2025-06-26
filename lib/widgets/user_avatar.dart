import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  final double radius;

  const UserAvatar({super.key, required this.userId, this.radius = 20.0});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircleAvatar(radius: radius, child: const Icon(Icons.person));
        }
        final photoURL = snapshot.data?.data()?['photoURL'] as String?;

        return CircleAvatar(
          radius: radius,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          backgroundImage:
              (photoURL != null && !photoURL.contains('dicebear.com'))
              ? NetworkImage(photoURL)
              : null,
          child: (photoURL != null && photoURL.contains('dicebear.com'))
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(radius * 2),
                  child: SvgPicture.network(photoURL, fit: BoxFit.cover),
                )
              : (photoURL == null ? const Icon(Icons.person) : null),
        );
      },
    );
  }
}
