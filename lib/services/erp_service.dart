import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/marks_model.dart';
import '../models/attendance_model.dart';
import '../models/performance_model.dart';
import '../models/notification_model.dart';

/// ERP Service for advanced academic operations.
/// Handles GPA/CGPA calculation, attendance tracking, performance analytics, etc.
class ERPService {
  final FirebaseFirestore _db;

  ERPService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // =========================================================================
  // ATTENDANCE OPERATIONS
  // =========================================================================

  Future<void> recordAttendance(AttendanceModel attendance) async {
    final query = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: attendance.studentId)
        .where('subjectId', isEqualTo: attendance.subjectId)
        .where('year', isEqualTo: attendance.year)
        .where('semester', isEqualTo: attendance.semester)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update(attendance.toMap());
    } else {
      await _db.collection('attendance').add(attendance.toMap());
    }
  }

  Future<double> getAttendancePercentage(
    String studentId,
    String subjectId,
    int year,
    int semester,
  ) async {
    final query = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();

    final attendance = query.docs
        .map((doc) => AttendanceModel.fromMap(doc.data()))
        .firstWhere(
          (a) =>
              a.subjectId == subjectId &&
              a.year == year &&
              a.semester == semester,
          orElse: () => AttendanceModel(
            studentId: studentId,
            subjectId: subjectId,
            year: year,
            semester: semester,
          ),
        );
    return attendance.percentage;
  }

  Future<double> getOverallAttendancePercentage(
    String studentId,
    int year,
    int semester,
  ) async {
    final query = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();

    final attendanceList = query.docs
        .map((doc) => AttendanceModel.fromMap(doc.data()))
        .where((a) => a.year == year && a.semester == semester)
        .toList();

    if (attendanceList.isEmpty) return 0.0;

    double totalPercentage = 0.0;
    for (final attendance in attendanceList) {
      totalPercentage += attendance.percentage;
    }

    return totalPercentage / attendanceList.length;
  }

  // =========================================================================
  // MARKS AND GPA OPERATIONS
  // =========================================================================

  Future<double> calculateSemesterGPA(
    String studentId,
    int year,
    int semester,
  ) async {
    final marks = await _db
        .collection('marks')
        .where('studentId', isEqualTo: studentId)
        .get();

    final semesterMarks = marks.docs
        .map((doc) => MarksModel.fromMap(doc.data()))
        .where((m) => m.year == year && m.semester == semester)
        .toList();

    if (semesterMarks.isEmpty) return 0.0;

    double totalGradePoints = 0.0;
    int totalCredits = semesterMarks.length;

    for (final mark in semesterMarks) {
      totalGradePoints += mark.gradePoint;
    }

    if (totalCredits == 0) return 0.0;
    return totalGradePoints / totalCredits;
  }

  Future<double> calculateCGPA(String studentId, int uptillSemester) async {
    final marks = await _db
        .collection('marks')
        .where('studentId', isEqualTo: studentId)
        .get();

    final relevantMarks = marks.docs
        .map((doc) => MarksModel.fromMap(doc.data()))
        .where((m) => m.semester <= uptillSemester)
        .toList();

    if (relevantMarks.isEmpty) return 0.0;

    double totalGradePoints = 0.0;
    int totalCredits = relevantMarks.length;

    for (final mark in relevantMarks) {
      totalGradePoints += mark.gradePoint;
    }

    if (totalCredits == 0) return 0.0;
    return totalGradePoints / totalCredits;
  }

  Future<double> calculateSemesterAverage(
    String studentId,
    int year,
    int semester,
  ) async {
    final marks = await _db
        .collection('marks')
        .where('studentId', isEqualTo: studentId)
        .get();

    final semesterMarks = marks.docs
        .map((doc) => MarksModel.fromMap(doc.data()))
        .where((m) => m.year == year && m.semester == semester)
        .toList();

    if (semesterMarks.isEmpty) return 0.0;

    double totalMarks = 0.0;
    int count = semesterMarks.length;

    for (final mark in semesterMarks) {
      totalMarks += mark.total;
    }

    if (count == 0) return 0.0;
    return totalMarks / count;
  }

  // =========================================================================
  // PERFORMANCE ANALYTICS
  // =========================================================================

  Future<PerformanceModel> getPerformanceAnalytics(
    String studentId,
    int year,
    int semester,
  ) async {
    final gpa = await calculateSemesterGPA(studentId, year, semester);
    final attendance = await getOverallAttendancePercentage(
      studentId,
      year,
      semester,
    );
    final average = await calculateSemesterAverage(studentId, year, semester);

    // Identify strengths and weaknesses
    final marks = await _db
        .collection('marks')
        .where('studentId', isEqualTo: studentId)
        .get();

    final semesterMarks = marks.docs
        .map((doc) => MarksModel.fromMap(doc.data()))
        .where((m) => m.year == year && m.semester == semester)
        .toList();

    final strengths = <String>[];
    final weaknesses = <String>[];

    for (final mark in semesterMarks) {
      if (mark.gradePoint >= 8.0) {
        strengths.add(mark.subjectId);
      } else if (mark.gradePoint < 5.0) {
        weaknesses.add(mark.subjectId);
      }
    }

    return PerformanceModel(
      studentId: studentId,
      semester: semester,
      year: year,
      averageMarks: average,
      gpa: gpa,
      attendancePercentage: attendance,
      strengths: strengths,
      weaknesses: weaknesses,
    );
  }

  // =========================================================================
  // NOTIFICATIONS
  // =========================================================================

  Future<void> sendNotification(NotificationModel notification) async {
    await _db.collection('notifications').add(notification.toMap());
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdDate', descending: true)
        .limit(50)
        .get();

    return snap.docs
        .map((doc) => NotificationModel.fromMap(doc.data()))
        .toList();
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    return snap.docs.length;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // =========================================================================
  // SUBJECT ASSIGNMENTS
  // =========================================================================

  Future<List<String>> getSubjectsForYearSemester(
    int year,
    int semester,
  ) async {
    final snap = await _db
        .collection('subjects')
        .where('year', isEqualTo: year)
        .where('semester', isEqualTo: semester)
        .get();

    return snap.docs.map((doc) => doc.id).toList();
  }
}
