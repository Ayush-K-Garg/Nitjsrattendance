import 'package:flutter/foundation.dart';
import 'package:attend/models/attendance_record.dart'; // Assuming your Course model is here or you can rename it

// A new model to hold the student's details
class Student {
  final String name;
  final String regNo;

  Student({required this.name, required this.regNo});

  // For caching
  Map<String, dynamic> toMap() => {'name': name, 'regNo': regNo};
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(name: map['name'], regNo: map['regNo']);
  }
}


// This is your updated AttendanceRecord, now named Course to be more descriptive
// and including the new facultyName field.
// NOTE: You might need to update this in your `attendance_record.dart` file
// or replace it with this model.
class Course {
  final String subjectCode;
  final String subjectName;
  final String facultyName; // <-- NEW FIELD
  final int classesAttended;
  final int totalClasses;

  double get percentage => totalClasses == 0 ? 0.0 : (classesAttended / totalClasses) * 100;

  Course({
    required this.subjectCode,
    required this.subjectName,
    required this.facultyName, // <-- NEW FIELD
    required this.classesAttended,
    required this.totalClasses,
  });

  // For caching
  Map<String, dynamic> toMap() {
    return {
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'facultyName': facultyName,
      'classesAttended': classesAttended,
      'totalClasses': totalClasses,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      subjectCode: map['subjectCode'],
      subjectName: map['subjectName'],
      facultyName: map['facultyName'],
      classesAttended: map['classesAttended'],
      totalClasses: map['totalClasses'],
    );
  }
}


// A new container class to hold ALL the data scraped from the portal.
// This is what the scraping service will now return.
class ScrapedData {
  final Student student;
  final List<Course> courses;

  ScrapedData({required this.student, required this.courses});

  // For caching
  Map<String, dynamic> toMap() {
    return {
      'student': student.toMap(),
      'courses': courses.map((c) => c.toMap()).toList(),
    };
  }

  factory ScrapedData.fromMap(Map<String, dynamic> map) {
    return ScrapedData(
      student: Student.fromMap(map['student']),
      courses: (map['courses'] as List).map((c) => Course.fromMap(c)).toList(),
    );
  }
}
