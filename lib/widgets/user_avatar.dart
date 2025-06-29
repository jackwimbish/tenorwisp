import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserAvatar extends StatelessWidget {
  final String? photoURL;
  final double radius;

  const UserAvatar({super.key, required this.photoURL, this.radius = 20.0});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoURL != null && photoURL!.isNotEmpty;
    final isSvg = hasPhoto && photoURL!.contains('dicebear.com');

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      backgroundImage: (hasPhoto && !isSvg) ? NetworkImage(photoURL!) : null,
      child: !hasPhoto
          ? Icon(Icons.person, size: radius)
          : isSvg
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: SvgPicture.network(
                photoURL!,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
              ),
            )
          : null,
    );
  }
}
