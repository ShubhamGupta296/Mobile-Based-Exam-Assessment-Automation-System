import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single lecture attendance session recorded by a teacher.
class DailyAttendanceModel {
  final String id;
  final String department;
  final int year;
  final int semester;
  final String division;
  final String subjectId;
  final String teacherId;
  final DateTime date;
  final int lectureNumber;
  final List<String> presentStudentIds;
  final List<String> absentStudentIds;
  final int totalStudents;
  final DateTime createdAt;

  DailyAttendanceModel({
    this.id = '',
    this.department = 'Computer Engineering',
    this.year = 1,
    this.semester = 1,
    this.division = 'A',
    required this.subjectId,
    this.teacherId = '',
    required this.date,
    this.lectureNumber = 1,
    required this.presentStudentIds,
    required this.absentStudentIds,
    int? totalStudents,
    DateTime? createdAt,
  })  : totalStudents = totalStudents ?? (presentStudentIds.length + absentStudentIds.length),
        createdAt = createdAt ?? DateTime.now();

  double get attendancePercentage =>
      totalStudents > 0 ? (presentStudentIds.length / totalStudents) * 100 : 0.0;

  factory DailyAttendanceModel.fromMap(Map<String, dynamic> map, {String docId = ''}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final present = (map['presentStudentIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    final absent = (map['absentStudentIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    return DailyAttendanceModel(
      id: docId.isNotEmpty ? docId : (map['id'] as String? ?? ''),
      department: (map['department'] as String?) ?? 'Computer Engineering',
      year: (map['year'] as int?) ?? 1,
      semester: (map['semester'] as int?) ?? 1,
      division: (map['division'] as String?) ?? 'A',
      subjectId: (map['subjectId'] as String?) ?? '',
      teacherId: (map['teacherId'] as String?) ?? '',
      date: parseDate(map['date']),
      lectureNumber: (map['lectureNumber'] as int?) ?? 1,
      presentStudentIds: present,
      absentStudentIds: absent,
      totalStudents: (map['totalStudents'] as int?) ?? (present.length + absent.length),
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'department': department,
      'year': year,
      'semester': semester,
      'division': division,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'date': Timestamp.fromDate(date),
      'lectureNumber': lectureNumber,
      'presentStudentIds': presentStudentIds,
      'absentStudentIds': absentStudentIds,
      'totalStudents': totalStudents,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
