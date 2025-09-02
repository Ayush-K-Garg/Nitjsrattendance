import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attend/screens/home_screen.dart';
import 'package:attend/services/secure_storage_service.dart';
import 'package:attend/services/web_scraping_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = SecureStorageService();
  final _scraper = WebScrapingService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = true;

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final username = _usernameController.text;
        final password = _passwordController.text;

        // --- FIXED ---
        // Changed the method call from the old 'getAttendance' to the new 'getScrapedData'.
        // This is just to verify the credentials are correct before proceeding.
        await _scraper.getScrapedData(username, password);

        if (_rememberMe) {
          await _storage.saveCredentials(username, password);
        } else {
          await _storage.deleteCredentials();
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight - kToolbarHeight),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your student portal',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'User ID / Roll No.'),
                      validator: (value) => value!.isEmpty ? 'Please enter your User ID' : null,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? true;
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: const Text(
                            'Remember Me',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                          : const Text('LOGIN', style: TextStyle(fontSize: 16)),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

