import 'package:flutter/material.dart';
import 'package:attend/models/scraped_data.dart'; // <-- MODIFIED: Import new data model
import 'package:attend/services/secure_storage_service.dart';
import 'package:attend/services/web_scraping_service.dart';
import 'package:attend/widgets/attendance_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with AutomaticKeepAliveClientMixin {
  final WebScrapingService _webScraper = WebScrapingService();
  final SecureStorageService _storage = SecureStorageService();
  // --- MODIFIED: The future now holds all our scraped data ---
  late Future<ScrapedData> _futureScrapedData;

  final _loadingStatusNotifier = ValueNotifier<String>('Initializing...');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loadingStatusNotifier.value = 'Preparing to fetch data...';
      // --- MODIFIED: Call the new fetch method ---
      _futureScrapedData = _getScrapedData();
    });
  }

  // --- MODIFIED: This method now gets the complete ScrapedData object ---
  Future<ScrapedData> _getScrapedData() async {
    final creds = await _storage.getCredentials();
    if (creds == null) {
      // This case should ideally be handled by a splash screen logic
      // to redirect to login if no credentials are found.
      throw Exception("Credentials not found. Please log out and log back in.");
    }
    // --- MODIFIED: Call the new service method ---
    return _webScraper.getScrapedData(
      creds['username']!,
      creds['password']!,
      progressNotifier: _loadingStatusNotifier,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          // --- MODIFIED: FutureBuilder now expects ScrapedData ---
          child: FutureBuilder<ScrapedData>(
            future: _futureScrapedData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      ValueListenableBuilder<String>(
                        valueListenable: _loadingStatusNotifier,
                        builder: (context, value, child) {
                          return Text(
                            value,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Error: ${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.courses.isEmpty) {
                return const Center(
                  child: Text(
                    'No attendance records found.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              } else {
                // --- NEW: Extract student and course data ---
                final student = snapshot.data!.student;
                final courses = snapshot.data!.courses;
        
                // --- NEW: A Column to hold the new layout ---
                return Column(
                  children: [
                    // --- NEW: Student Info Header ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reg No: ${student.regNo}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- NEW: Expanded ListView for courses ---
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          // --- MODIFIED: Pass the new 'Course' object to the card ---
                          // Note: This will cause an error until we update AttendanceCard
                          return AttendanceCard(course: courses[index]);
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
