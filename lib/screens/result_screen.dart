import 'package:flutter/material.dart';
import 'package:attend/models/result_record.dart';
import 'package:attend/services/secure_storage_service.dart';
import 'package:attend/services/web_scraping_service.dart';
import 'package:attend/widgets/result_card.dart';

class ResultScreen extends StatefulWidget {
  // We don't need credentials here anymore since it's managed by the home screen
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with AutomaticKeepAliveClientMixin {
  final WebScrapingService _webScraper = WebScrapingService();
  final SecureStorageService _storage = SecureStorageService();
  late Future<List<ResultRecord>> _futureResults;

  // A notifier to hold the current loading status message
  final _loadingStatusNotifier = ValueNotifier<String>('Initializing...');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loadingStatusNotifier.value = 'Preparing to fetch data...';
      _futureResults = _getResultsData();
    });
  }

  Future<List<ResultRecord>> _getResultsData() async {
    final creds = await _storage.getCredentials();
    if (creds == null) {
      throw Exception("Credentials not found.");
    }
    // Pass the notifier to the service
    return _webScraper.getResults(
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
        child: FutureBuilder<List<ResultRecord>>(
          future: _futureResults,
          builder: (context, snapshot) {
            // --- UPDATED LOADING UI ---
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
            }
            // --- END OF UPDATED UI ---
            else if (snapshot.hasError) {
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
                  'No result records found.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            } else {
              final records = snapshot.data!;
              return ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  return ResultCard(record: records[index]);
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

