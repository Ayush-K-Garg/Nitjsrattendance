import 'dart:convert';

class AttendanceRecord {
  final String subjectName;
  final String subjectCode;
  final int classesAttended;
  final int totalClasses;

  AttendanceRecord({
    required this.subjectName,
    required this.subjectCode,
    required this.classesAttended,
    required this.totalClasses,
  });

  double get percentage {
    if (totalClasses == 0) return 0.0;
    return (classesAttended / totalClasses) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'classesAttended': classesAttended,
      'totalClasses': totalClasses,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      subjectName: map['subjectName'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      classesAttended: map['classesAttended']?.toInt() ?? 0,
      totalClasses: map['totalClasses']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceRecord.fromJson(String source) =>
      AttendanceRecord.fromMap(json.decode(source));
}

