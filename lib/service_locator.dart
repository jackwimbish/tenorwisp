import 'package:get_it/get_it.dart';
import 'package:tenorwisp/services/auth_service.dart';
import 'package:tenorwisp/services/chat_service.dart';
import 'package:tenorwisp/services/media_service.dart';
import 'package:tenorwisp/services/storage_service.dart';
import 'package:tenorwisp/services/submission_service.dart';
import 'package:tenorwisp/services/user_service.dart';
import 'package:tenorwisp/services/video_cache_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Services
  getIt.registerLazySingleton(() => AuthService());
  getIt.registerLazySingleton(() => ChatService());
  getIt.registerLazySingleton(() => MediaService());
  getIt.registerLazySingleton(() => StorageService());
  getIt.registerLazySingleton(() => SubmissionService());
  getIt.registerLazySingleton(() => UserService());
  getIt.registerLazySingleton(() => VideoCacheService());
}
