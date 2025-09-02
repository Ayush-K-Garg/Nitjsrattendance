import 'dart:convert';

class ResultRecord {
  final String subjectName;
  final String subjectCode;
  final String grade;
  final String sgpa;

  ResultRecord({
    required this.subjectName,
    required this.subjectCode,
    required this.grade,
    required this.sgpa,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'grade': grade,
      'sgpa': sgpa,
    };
  }

  factory ResultRecord.fromMap(Map<String, dynamic> map) {
    return ResultRecord(
      subjectName: map['subjectName'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      grade: map['grade'] ?? '',
      sgpa: map['sgpa'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ResultRecord.fromJson(String source) =>
      ResultRecord.fromMap(json.decode(source));
}

