import 'package:flutter/material.dart';
import 'package:attend/screens/home_screen.dart';
import 'package:attend/screens/login_screen.dart';
import 'package:attend/services/secure_storage_service.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final creds = await SecureStorageService().getCredentials();
    // A small delay to show splash screen effect
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (creds != null) {
      // If logged in, go to HomeScreen.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // If not logged in, go to LoginScreen.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is effectively the splash screen
    return const Scaffold(
      backgroundColor: Color(0xff121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text('Checking credentials...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

