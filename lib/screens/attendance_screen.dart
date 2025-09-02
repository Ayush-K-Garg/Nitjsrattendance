import 'package:flutter/material.dart';
import 'package:attend/models/attendance_record.dart';
import 'package:attend/services/secure_storage_service.dart';
import 'package:attend/services/web_scraping_service.dart';
import 'package:attend/widgets/attendance_card.dart';

class AttendanceScreen extends StatefulWidget {
  // This screen no longer accepts credentials in its constructor
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with AutomaticKeepAliveClientMixin {
  final WebScrapingService _webScraper = WebScrapingService();
  final SecureStorageService _storage = SecureStorageService();
  late Future<List<AttendanceRecord>> _futureAttendance;

  final _loadingStatusNotifier = ValueNotifier<String>('Initializing...');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loadingStatusNotifier.value = 'Preparing to fetch data...';
      _futureAttendance = _getAttendanceData();
    });
  }

  Future<List<AttendanceRecord>> _getAttendanceData() async {
    // It now fetches its own credentials from secure storage
    final creds = await _storage.getCredentials();
    if (creds == null) {
      throw Exception("Credentials not found.");
    }
    return _webScraper.getAttendance(
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
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: FutureBuilder<List<AttendanceRecord>>(
          future: _futureAttendance,
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
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No attendance records found.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            } else {
              final records = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  return AttendanceCard(record: records[index]);
                },
              );
            }
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

