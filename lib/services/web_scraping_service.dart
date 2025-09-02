import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart' as parser;
import 'package:attend/models/attendance_record.dart';
import 'package:attend/models/result_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebScrapingService {
  // --- ATTENDANCE PORTAL VALUES ---
  final String _attendanceLoginUrl = 'https://online.nitjsr.ac.in/sap/Login.aspx';
  final String _attendanceDataUrl = 'https://online.nitjsr.ac.in/sap/StudentAttendance/ClassAttendance.aspx';
  final String _attendanceUsernameFieldId = 'txtuser_id';
  final String _attendancePasswordFieldId = 'txtpassword';
  final String _attendanceLoginButtonId = 'btnsubmit';
  final String _attendanceTableSelector = '#ContentPlaceHolder1_gv';

  // --- RESULT PORTAL VALUES (STILL PLACEHOLDERS) ---
  // final String _resultLoginUrl = 'http://202.168.87.90/StudentPortal/Login.aspx';

  // --- CACHING SETUP ---
  static const String _attendanceCacheKey = 'attendance_cache';
  static const String _resultCacheKey = 'result_cache';
  static const String _attendanceTimestampKey = 'attendance_timestamp';
  static const String _resultTimestampKey = 'result_timestamp';
  final Duration _cacheDuration = const Duration(hours: 4);

  Future<List<AttendanceRecord>> getAttendance(String u, String p, {ValueNotifier<String>? progressNotifier}) async {
    try {
      var cache = await _loadFromCache<AttendanceRecord>(_attendanceCacheKey, _attendanceTimestampKey, AttendanceRecord.fromMap);
      if (cache != null) {
        progressNotifier?.value = 'Loading attendance from cache...';
        await Future.delayed(const Duration(milliseconds: 500));
        return cache;
      }

      final networkData = await _fetchAndParseAttendance(u, p, progressNotifier: progressNotifier);
      await _saveToCache(_attendanceCacheKey, _attendanceTimestampKey, networkData);
      return networkData;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AttendanceRecord>> _fetchAndParseAttendance(String username, String password, {ValueNotifier<String>? progressNotifier}) async {
    final Completer<List<AttendanceRecord>> scrapingCompleter = Completer();
    HeadlessInAppWebView? webView;
    bool loginAttempted = false;

    webView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_attendanceLoginUrl)),
      onLoadStop: (controller, url) async {
        try {
          final currentUrl = url.toString();
          debugPrint("Page finished loading: $currentUrl");

          if (currentUrl.contains('Login.aspx')) {
            if (loginAttempted) {
              // If we are back on the login page after trying to log in, it failed.
              if (!scrapingCompleter.isCompleted) {
                scrapingCompleter.completeError(Exception("Login failed. Please check your credentials."));
              }
              return;
            }

            progressNotifier?.value = 'Entering credentials...';
            // Wait for the username field to be ready before trying to fill it
            await _waitForElement(controller, _attendanceUsernameFieldId);

            await controller.evaluateJavascript(source: """
              document.getElementById('$_attendanceUsernameFieldId').value = '$username';
              document.getElementById('$_attendancePasswordFieldId').value = '$password';
              document.getElementById('$_attendanceLoginButtonId').click();
            """);
            loginAttempted = true;
            progressNotifier?.value = 'Verifying login...';

          } else if (currentUrl.contains('Home.aspx')) {
            // SUCCESS! The redirect to the home page is our proof of a successful login.
            progressNotifier?.value = 'Login successful! Fetching attendance...';
            await controller.loadUrl(urlRequest: URLRequest(url: WebUri(_attendanceDataUrl)));

          } else if (currentUrl.contains('ClassAttendance.aspx')) {
            progressNotifier?.value = 'Parsing data...';
            await _waitForElement(controller, 'ContentPlaceHolder1_gv');

            String? html = await controller.getHtml();
            if (html == null) throw Exception("Failed to get attendance page HTML.");

            final records = _parseAttendanceHtml(html);
            if (!scrapingCompleter.isCompleted) {
              scrapingCompleter.complete(records);
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

  Future<void> _saveToCache(String key, String tsKey, List<dynamic> data) async {
    final p = await SharedPreferences.getInstance();
    p.setString(key, json.encode(data.map((i) => i.toMap()).toList()));
    p.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<T>?> _loadFromCache<T>(String key, String tsKey, T Function(Map<String, dynamic>) fromMap) async {
    final p = await SharedPreferences.getInstance();
    final ts = p.getInt(tsKey);
    final data = p.getString(key);
    if (ts != null && data != null && DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) < _cacheDuration) {
      return (json.decode(data) as List).map((i) => fromMap(i)).toList();
    }
    return null;
  }

  List<AttendanceRecord> _parseAttendanceHtml(String htmlString) {
    final document = parser.parse(htmlString);
    final List<AttendanceRecord> records = [];
    final table = document.querySelector(_attendanceTableSelector);

    if (table == null) {
      throw Exception("Could not find the attendance table. Please verify the `_attendanceTableSelector` in the code.");
    }

    final rows = table.querySelectorAll('tr');
    for (var i = 1; i < rows.length; i++) {
      final cells = rows[i].querySelectorAll('td');
      if (cells.length > 5) {
        final subjectCode = cells[1].text.trim();
        final subjectName = cells[2].text.trim();
        final presentTotal = cells[4].text.trim().split('/');

        if (presentTotal.length == 2) {
          final classesAttended = int.tryParse(presentTotal[0]) ?? 0;
          final totalClasses = int.tryParse(presentTotal[1]) ?? 0;

          records.add(AttendanceRecord(
            subjectCode: subjectCode,
            subjectName: subjectName,
            classesAttended: classesAttended,
            totalClasses: totalClasses,
          ));
        }
      }
    }
    return records;
  }

  Future<List<ResultRecord>> getResults(String u, String p, {ValueNotifier<String>? progressNotifier}) async {
    progressNotifier?.value = 'Result feature not yet implemented.';
    await Future.delayed(const Duration(seconds: 2));
    return [];
  }
}

