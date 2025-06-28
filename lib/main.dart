import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'firebase_options.dart';
import 'app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart'; // <-- Import your new HomeScreen
import 'main_app_shell.dart'; // <-- Import the new main app shell
import 'package:tenorwisp/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TenorWisp',
      theme: tenorWispTheme,
      home: const AuthWrapper(), // <-- Use the new AuthWrapper as the home
    );
  }
}

// This is the new widget that will handle the auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to the auth state changes stream
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Connection state handling
        if (snapshot.connectionState == ConnectionState.waiting) {
          // If the connection is waiting, show a loading indicator
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Error handling
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong!')),
          );
        }

        // 3. Auth state logic
        if (snapshot.hasData) {
          // If snapshot.hasData is true, it means the stream has a User object
          // So, the user is logged in. Show the MainAppShell.
          return const MainAppShell();
        } else {
          // If snapshot.hasData is false, the user is logged out.
          // Show the LoginScreen.
          return const LoginScreen();
        }
      },
    );
  }
}
