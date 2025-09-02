import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart' as parser;
import 'package:attend/models/scraped_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attend/models/result_record.dart';

class WebScrapingService {
  // --- ATTENDANCE PORTAL VALUES ---
  final String _loginUrl = 'https://online.nitjsr.ac.in/sap/Login.aspx';
  final String _homeUrl = 'https://online.nitjsr.ac.in/sap/Home/Home.aspx';
  final String _attendanceUrl = 'https://online.nitjsr.ac.in/sap/StudentAttendance/ClassAttendance.aspx';

  // --- HTML Element IDs ---
  final String _usernameFieldId = 'txtuser_id';
  final String _passwordFieldId = 'txtpassword';
  final String _loginButtonId = 'btnsubmit';
  final String _studentNameId = 'lbluser'; // The correct, reliable ID for the welcome message
  final String _attendanceTableId = 'ContentPlaceHolder1_gv';

  // --- CACHING SETUP ---
  static const String _cacheKey = 'scraped_data_cache';
  static const String _timestampKey = 'scraped_data_timestamp';
  final Duration _cacheDuration = const Duration(hours: 4);

  Future<ScrapedData> getScrapedData(String u, String p, {ValueNotifier<String>? progressNotifier}) async {
    try {
      final cache = await _loadFromCache();
      if (cache != null) {
        progressNotifier?.value = 'Loading data from cache...';
        await Future.delayed(const Duration(milliseconds: 500));
        return cache;
      }

      final networkData = await _fetchAndParseAllData(u, p, progressNotifier: progressNotifier);
      await _saveToCache(networkData);
      return networkData;
    } catch (e) {
      debugPrint("Error in getScrapedData: $e");
      rethrow;
    }
  }

  Future<List<ResultRecord>> getResults(String u, String p, {ValueNotifier<String>? progressNotifier}) async {
    progressNotifier?.value = 'Result feature not yet implemented.';
    await Future.delayed(const Duration(seconds: 2));
    return [];
  }

  Future<ScrapedData> _fetchAndParseAllData(String username, String password, {ValueNotifier<String>? progressNotifier}) async {
    final Completer<ScrapedData> scrapingCompleter = Completer();
    HeadlessInAppWebView? webView;

    Student? studentDetails;
    List<Course>? courseDetails;

    webView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_loginUrl)),
      onLoadStop: (controller, url) async {
        try {
          final currentUrl = url.toString();
          debugPrint("Page finished loading: $currentUrl");

          if (currentUrl.contains('Login.aspx')) {
            progressNotifier?.value = 'Entering credentials...';
            await _waitForElement(controller, _usernameFieldId);
            await controller.evaluateJavascript(source: """
              document.getElementById('$_usernameFieldId').value = '$username';
              document.getElementById('$_passwordFieldId').value = '$password';
              document.getElementById('$_loginButtonId').click();
            """);
            progressNotifier?.value = 'Verifying login...';
          } else if (currentUrl.contains('Home.aspx')) {
            progressNotifier?.value = 'Login successful! Fetching details...';

            await _waitForElement(controller, _studentNameId);

            String? homeHtml = await controller.getHtml();
            if (homeHtml == null) throw Exception("Failed to get home page HTML.");

            try {
              studentDetails = _parseStudentDetailsHtml(homeHtml, username);
            } catch (e) {
              debugPrint("Could not parse student details, using fallback values. Error: $e");
              studentDetails = Student(name: "Student", regNo: username);
            }

            progressNotifier?.value = 'Fetching attendance...';
            await controller.loadUrl(urlRequest: URLRequest(url: WebUri(_attendanceUrl)));

          } else if (currentUrl.contains('ClassAttendance.aspx')) {
            progressNotifier?.value = 'Parsing attendance data...';
            await _waitForElement(controller, _attendanceTableId);

            String? attendanceHtml = await controller.getHtml();
            if (attendanceHtml == null) throw Exception("Failed to get attendance page HTML.");

            // --- HTML LOGGING REMAINS ACTIVE FOR DEBUGGING ---
            if (kDebugMode) {
              debugPrint("--- ATTENDANCE PAGE HTML START ---");
              debugPrint(attendanceHtml);
              debugPrint("--- ATTENDANCE PAGE HTML END ---");
            }
            // ---------------------------------------------------

            courseDetails = _parseAttendanceHtml(attendanceHtml);

            if (studentDetails != null && courseDetails != null) {
              if (!scrapingCompleter.isCompleted) {
                scrapingCompleter.complete(ScrapedData(student: studentDetails!, courses: courseDetails!));
              }
            } else {
              if (!scrapingCompleter.isCompleted) {
                scrapingCompleter.completeError(Exception("Failed to scrape all necessary data."));
              }
            }
          }
        } catch (e) {
          if (!scrapingCompleter.isCompleted) {
            scrapingCompleter.completeError(e);
          }
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint("WebView Console: ${consoleMessage.message}");
      },
    );

    try {
      progressNotifier?.value = 'Initializing browser...';
      await webView.run();
      return await scrapingCompleter.future.timeout(const Duration(seconds: 45), onTimeout: () {
        throw TimeoutException("The scraping process took too long and timed out.");
      });
    } catch (e) {
      rethrow;
    } finally {
      await webView.dispose();
    }
  }

  // Uses the reliable 'lbluser' ID and cleans the "Welcome " prefix.
  Student _parseStudentDetailsHtml(String htmlString, String registrationNumber) {
    final document = parser.parse(htmlString);
    final nameElement = document.getElementById(_studentNameId);

    if (nameElement != null) {
      String fullName = nameElement.text.trim();
      // Remove the "Welcome " part to get just the name.
      String name = fullName.replaceFirst('Welcome ', '');
      return Student(name: name, regNo: registrationNumber);
    }

    throw Exception("Could not find student name element with ID '$_studentNameId'.");
  }


  // This function now uses the correct column indices based on the HTML log.
  List<Course> _parseAttendanceHtml(String htmlString) {
    final document = parser.parse(htmlString);
    final List<Course> courses = [];
    final table = document.getElementById(_attendanceTableId);

    if (table == null) {
      throw Exception("Could not find the attendance table on the page.");
    }

    final rows = table.querySelectorAll('tr');
    // Start from 1 to skip the header row.
    for (var i = 1; i < rows.length; i++) {
      final cells = rows[i].querySelectorAll('td');
      if (cells.length >= 7) { // Check there are enough columns
        try {
          // --- THIS IS THE FINAL FIX ---
          final subjectCode = cells[1].text.trim();      // Column 2
          final subjectName = cells[2].text.trim();      // Column 3
          final facultyName = cells[3].text.trim();      // Column 4
          final attendanceText = cells[4].text.trim(); // Column 5
          // --- END OF FIX ---

          final parts = attendanceText.split('/');

          if (parts.length == 2) {
            final attended = int.parse(parts[0]);
            final total = int.parse(parts[1]);

            courses.add(Course(
              subjectCode: subjectCode,
              subjectName: subjectName,
              facultyName: facultyName,
              classesAttended: attended,
              totalClasses: total,
            ));
          }
        } catch (e) {
          debugPrint("Skipping a row due to parsing error: $e");
        }
      }
    }
    return courses;
  }

  Future<bool> _waitForElement(InAppWebViewController controller, String elementId, {Duration timeout = const Duration(seconds: 15)}) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      final result = await controller.evaluateJavascript(source: "!!document.getElementById('$elementId')");
      if (result == true) {
        debugPrint("SUCCESS: Found element '$elementId'.");
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    debugPrint("TIMEOUT: Could not find element '$elementId' after ${timeout.inSeconds} seconds.");
    return false;
  }

  Future<void> _saveToCache(ScrapedData data) async {
    final p = await SharedPreferences.getInstance();
    p.setString(_cacheKey, json.encode(data.toMap()));
    p.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<ScrapedData?> _loadFromCache() async {
    final p = await SharedPreferences.getInstance();
    final ts = p.getInt(_timestampKey);
    final data = p.getString(_cacheKey);
    if (ts != null && data != null && DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) < _cacheDuration) {
      return ScrapedData.fromMap(json.decode(data));
    }
    return null;
  }
}

