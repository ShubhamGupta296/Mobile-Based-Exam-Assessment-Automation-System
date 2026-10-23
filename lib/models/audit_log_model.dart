import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an audit log entry for changes made to marks, results, or academic records.
class AuditLogModel {
  final String id;
  final String action; // e.g. MARKS_UPDATE, RESULT_LOCK, RESULT_UNLOCK, ATTENDANCE_RECORDED
  final String performedBy; // Email or UID of the user
  final String role; // teacher, admin
  final String studentId;
  final String studentRollNo;
  final String subjectId;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  AuditLogModel({
    this.id = '',
    required this.action,
    required this.performedBy,
    this.role = 'teacher',
    this.studentId = '',
    this.studentRollNo = '',
    this.subjectId = '',
    this.details = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AuditLogModel.fromMap(Map<String, dynamic> map, {String docId = ''}) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AuditLogModel(
      id: docId.isNotEmpty ? docId : (map['id'] as String? ?? ''),
      action: (map['action'] as String?) ?? 'UNKNOWN_ACTION',
      performedBy: (map['performedBy'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'teacher',
      studentId: (map['studentId'] as String?) ?? '',
      studentRollNo: (map['studentRollNo'] as String?) ?? '',
      subjectId: (map['subjectId'] as String?) ?? '',
      details: (map['details'] as Map<String, dynamic>?) ?? {},
      timestamp: parseTime(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'performedBy': performedBy,
      'role': role,
      'studentId': studentId,
      'studentRollNo': studentRollNo,
      'subjectId': subjectId,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
