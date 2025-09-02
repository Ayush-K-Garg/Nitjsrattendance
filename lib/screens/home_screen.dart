import 'package:flutter/material.dart';
import 'package:attend/screens/attendance_screen.dart';
import 'package:attend/screens/login_screen.dart';
import 'package:attend/screens/result_screen.dart';
import 'package:attend/services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  // No longer needs to accept credentials
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // The pages are now created without passing credentials
  final List<Widget> _pages = const [
    AttendanceScreen(),
    ResultScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _logout() async {
    // Clear credentials and cache
    // --- FIXED ---
    // Changed clearCredentials() to deleteCredentials() to match the service file.
    await SecureStorageService().deleteCredentials();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate to LoginScreen and remove all previous routes
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(

        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFFFFFFF), // Prevents default color fill
              child: ClipOval(
                child: Image.asset(
                  "assets/nitlogo.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),

          ),
      
          title: Text(_selectedIndex == 0 ? 'My Attendance' : 'My Results'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_rtl_outlined),
              activeIcon: Icon(Icons.checklist_rtl),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Results',
            ),
          ],
        ),
      ),
    );
  }
}
