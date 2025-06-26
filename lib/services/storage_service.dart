import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadChatMedia(
    String chatId,
    String userId,
    File file,
  ) async {
    final isVideo = file.path.toLowerCase().endsWith('.mp4');
    final fileExtension = isVideo ? 'mp4' : 'jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final destination = 'chat_media/$chatId/$userId/$fileName';

    final ref = _storage.ref(destination);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
