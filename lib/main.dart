import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attend/screens/auth_check_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF4A90E2),
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4A90E2),
        secondary: Color(0xFF4A90E2),
        surface: Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.black,
        background: Color(0xFF121212),
        onBackground: Colors.white,
        error: Colors.redAccent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'NIT JSR Portal',
      theme: darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthCheckScreen(),
    );
  }
}

