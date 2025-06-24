import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // 1. Validate the form
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do nothing
    }
  
    // 2. Show a loading indicator
    setState(() {
      _isLoading = true;
    });
  
    try {
      // 3. Sign in with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
  
      // After successful login, you can navigate to the home screen
      // For now, we'll just print a success message.
      // Important: check if the widget is still in the tree
      if (mounted) {
         // Navigate to your home screen or show success
         print("Login Successful!");
         // Example of navigation:
         // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
      }
  
    } on FirebaseAuthException catch (e) {
      // 4. Handle Firebase errors
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else {
        message = 'An error occurred. Please try again.';
      }
  
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 5. Hide loading indicator
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access theme data for cleaner code
    final theme = Theme.of(context);

    return Scaffold(
      // The background color is now set by the theme
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
	        Image.asset(
                  'assets/images/logo.png', // Make sure you have this asset
                  height: 100,
                  // If you don't have a logo, comment out this line
                ),
                // Text now uses the theme's default text styles
                Text(
                  'Welcome to TenorWisp!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 48),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // TextFormField inherits styles from inputDecorationTheme
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // ElevatedButton inherits styles from elevatedButtonTheme
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
