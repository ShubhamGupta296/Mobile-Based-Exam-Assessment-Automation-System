import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_model.dart';
import '../models/marks_model.dart';
import '../models/performance_model.dart';
import '../models/student_model.dart';
import 'erp_service.dart';
import 'firestore_service.dart';

/// Analytics DTOs
class TrendPoint {
  final String label;
  final double value;

  const TrendPoint({required this.label, required this.value});
}

class SubjectPerformance {
  final String subjectId;
  final double averageMarks;
  final double passPercentage;

  const SubjectPerformance({
    required this.subjectId,
    required this.averageMarks,
    required this.passPercentage,
  });
}

class TeacherAnalytics {
  final String teacherId;
  final double classAverage;
  final double passPercentage;
  final List<SubjectPerformance> subjectPerformance;
  final List<Map<String, dynamic>> topStudents;

  const TeacherAnalytics({
    required this.teacherId,
    required this.classAverage,
    required this.passPercentage,
    required this.subjectPerformance,
    required this.topStudents,
  });
}

class AdminAnalytics {
  final double overallAverage;
  final double overallPassPercentage;
  final Map<String, double> departmentPerformance;
  final Map<int, double> semesterPerformance;
  final Map<int, double> yearPerformance;
  final List<TrendPoint> gpaTrend;
  final List<TrendPoint> cgpaTrend;
  final List<TrendPoint> attendanceTrend;
  final List<SubjectPerformance> subjectPerformance;

  const AdminAnalytics({
    required this.overallAverage,
    required this.overallPassPercentage,
    required this.departmentPerformance,
    required this.semesterPerformance,
    required this.yearPerformance,
    required this.gpaTrend,
    required this.cgpaTrend,
    required this.attendanceTrend,
    required this.subjectPerformance,
  });
}

class ReportCardData {
  final StudentModel student;
  final List<MarksModel> marks;
  final List<AttendanceModel> attendance;
  final double gpa;
  final double cgpa;
  final double attendancePercentage;

  const ReportCardData({
    required this.student,
    required this.marks,
    required this.attendance,
    required this.gpa,
    required this.cgpa,
    required this.attendancePercentage,
  });
}

/// Analytics and Reporting Engine.
class AnalyticsService {
  final FirebaseFirestore _db;
  final ERPService _erp;
  final FirestoreService _firestore;

  AnalyticsService({
    FirebaseFirestore? db,
    ERPService? erp,
    FirestoreService? firestore,
  })  : _db = db ?? FirebaseFirestore.instance,
        _erp = erp ?? ERPService(db: db),
        _firestore = firestore ?? FirestoreService(db: db);

  // =========================================================================
  // STUDENT ANALYTICS
  // =========================================================================

  Future<PerformanceModel> getStudentAnalytics(
    String studentId,
    int year,
    int semester,
  ) {
    return _erp.getPerformanceAnalytics(studentId, year, semester);
  }

  Future<List<SubjectPerformance>> getStudentSubjectPerformance(
    String studentId,
    int year,
    int semester,
  ) async {
    final marks = await _firestore.getMarksByStudent(studentId);
    final filtered = marks
        .where((m) => m.year == year && m.semester == semester)
        .toList();

    return filtered
        .map(
          (m) => SubjectPerformance(
            subjectId: m.subjectId,
            averageMarks: m.total.toDouble(),
            passPercentage: m.total >= 40 ? 100.0 : 0.0,
          ),
        )
        .toList(growable: false);
  }

  Future<List<TrendPoint>> getStudentGpaTrend(String studentId) async {
    final marks = await _firestore.getMarksByStudent(studentId);
    final semesters = <int>{};
    for (final m in marks) {
      semesters.add(m.semester);
    }

    final points = <TrendPoint>[];
    for (final sem in semesters.toList()..sort()) {
      final year = marks.firstWhere((m) => m.semester == sem).year;
      final gpa = await _erp.calculateSemesterGPA(studentId, year, sem);
      points.add(TrendPoint(label: 'Sem $sem', value: gpa));
    }
    return points;
  }

  Future<List<TrendPoint>> getStudentCgpaTrend(String studentId) async {
    final marks = await _firestore.getMarksByStudent(studentId);
    final semesters = <int>{};
    for (final m in marks) {
      semesters.add(m.semester);
    }

    final points = <TrendPoint>[];
    for (final sem in semesters.toList()..sort()) {
      final cgpa = await _erp.calculateCGPA(studentId, sem);
      points.add(TrendPoint(label: 'Up to Sem $sem', value: cgpa));
    }
    return points;
  }

  Future<List<TrendPoint>> getStudentAttendanceTrend(
    String studentId,
    int year,
    int semester,
  ) async {
    final attendance = await _firestore.getAttendanceByStudent(studentId);
    final filtered = attendance
        .where((a) => a.year == year && a.semester == semester)
        .toList();

    return filtered
        .map(
          (a) => TrendPoint(
            label: a.subjectId,
            value: a.percentage,
          ),
        )
        .toList(growable: false);
  }

  // =========================================================================
  // TEACHER ANALYTICS
  // =========================================================================

  Future<TeacherAnalytics> getTeacherAnalytics(String teacherId) async {
    final subjectsSnap = await _db
        .collection('subjects')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    final subjectIds =
        subjectsSnap.docs.map((d) => d.data()['id'] as String? ?? d.id).toSet();

    final marksSnap = await _db.collection('marks').get();
    final relevantMarks = marksSnap.docs
        .map((d) => MarksModel.fromMap(d.data()))
        .where((m) => subjectIds.contains(m.subjectId))
        .toList();

    final subjectPerf = <SubjectPerformance>[];
    for (final sid in subjectIds) {
      final subMarks = relevantMarks.where((m) => m.subjectId == sid).toList();
      if (subMarks.isEmpty) continue;
      final avg =
          subMarks.map((m) => m.total).reduce((a, b) => a + b) / subMarks.length;
      final passCount = subMarks.where((m) => m.total >= 40).length;
      subjectPerf.add(
        SubjectPerformance(
          subjectId: sid,
          averageMarks: avg,
          passPercentage: (passCount / subMarks.length) * 100,
        ),
      );
    }

    final classAvg = relevantMarks.isEmpty
        ? 0.0
        : relevantMarks.map((m) => m.total).reduce((a, b) => a + b) /
            relevantMarks.length;
    final passPct = relevantMarks.isEmpty
        ? 0.0
        : (relevantMarks.where((m) => m.total >= 40).length /
                relevantMarks.length) *
            100;

    final topStudents = _topStudentsFromMarks(relevantMarks, limit: 5);

    return TeacherAnalytics(
      teacherId: teacherId,
      classAverage: classAvg,
      passPercentage: passPct,
      subjectPerformance: subjectPerf,
      topStudents: topStudents,
    );
  }

  List<Map<String, dynamic>> _topStudentsFromMarks(
    List<MarksModel> marks, {
    int limit = 5,
  }) {
    final totals = <String, int>{};
    final counts = <String, int>{};

    for (final m in marks) {
      totals[m.studentId] = (totals[m.studentId] ?? 0) + m.total;
      counts[m.studentId] = (counts[m.studentId] ?? 0) + 1;
    }

    final averages = totals.entries
        .map(
          (e) => {
            'studentId': e.key,
            'average': e.value / (counts[e.key] ?? 1),
          },
        )
        .toList()
      ..sort(
        (a, b) =>
            (b['average'] as double).compareTo(a['average'] as double),
      );

    return averages.take(limit).toList(growable: false);
  }

  // =========================================================================
  // ADMIN ANALYTICS
  // =========================================================================

  Future<AdminAnalytics> getAdminAnalytics() async {
    final marksSnap = await _db.collection('marks').get();
    final allMarks =
        marksSnap.docs.map((d) => MarksModel.fromMap(d.data())).toList();

    final students = await _firestore.getAllStudents();
    final attendanceSnap = await _db.collection('attendance').get();
    final allAttendance = attendanceSnap.docs
        .map((d) => AttendanceModel.fromMap(d.data()))
        .toList();

    final overallAvg = allMarks.isEmpty
        ? 0.0
        : allMarks.map((m) => m.total).reduce((a, b) => a + b) / allMarks.length;
    final passPct = allMarks.isEmpty
        ? 0.0
        : (allMarks.where((m) => m.total >= 40).length / allMarks.length) * 100;

    final deptPerf = <String, double>{};
    for (final student in students) {
      final studentMarks =
          allMarks.where((m) => m.studentId == student.id).toList();
      if (studentMarks.isEmpty) continue;
      final avg = studentMarks.map((m) => m.total).reduce((a, b) => a + b) /
          studentMarks.length;
      deptPerf[student.branch] =
          ((deptPerf[student.branch] ?? 0) + avg) / 2;
    }

    final semPerf = <int, double>{};
    for (final m in allMarks) {
      semPerf[m.semester] =
          ((semPerf[m.semester] ?? 0) + m.total) / 2;
    }

    final yearPerf = <int, double>{};
    for (final m in allMarks) {
      yearPerf[m.year] = ((yearPerf[m.year] ?? 0) + m.total) / 2;
    }

    final subjectPerf = <String, List<MarksModel>>{};
    for (final m in allMarks) {
      subjectPerf.putIfAbsent(m.subjectId, () => []).add(m);
    }

    final subjectPerformance = subjectPerf.entries.map((e) {
      final avg = e.value.map((m) => m.total).reduce((a, b) => a + b) /
          e.value.length;
      final pass = e.value.where((m) => m.total >= 40).length;
      return SubjectPerformance(
        subjectId: e.key,
        averageMarks: avg,
        passPercentage: (pass / e.value.length) * 100,
      );
    }).toList();

    final gpaTrend = <TrendPoint>[];
    final cgpaTrend = <TrendPoint>[];
    for (var sem = 1; sem <= 8; sem++) {
      final semMarks = allMarks.where((m) => m.semester == sem).toList();
      if (semMarks.isEmpty) continue;
      final avgGp =
          semMarks.map((m) => m.gradePoint).reduce((a, b) => a + b) /
              semMarks.length;
      gpaTrend.add(TrendPoint(label: 'Sem $sem', value: avgGp));
      cgpaTrend.add(TrendPoint(label: 'Sem $sem', value: avgGp));
    }

    final attTrend = <TrendPoint>[];
    final attBySubject = <String, List<double>>{};
    for (final a in allAttendance) {
      attBySubject.putIfAbsent(a.subjectId, () => []).add(a.percentage);
    }
    for (final entry in attBySubject.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      attTrend.add(TrendPoint(label: entry.key, value: avg));
    }

    return AdminAnalytics(
      overallAverage: overallAvg,
      overallPassPercentage: passPct,
      departmentPerformance: deptPerf,
      semesterPerformance: semPerf,
      yearPerformance: yearPerf,
      gpaTrend: gpaTrend,
      cgpaTrend: cgpaTrend,
      attendanceTrend: attTrend,
      subjectPerformance: subjectPerformance,
    );
  }

  // =========================================================================
  // REPORTS
  // =========================================================================

  Future<ReportCardData> generateReportCard(String studentId) async {
    final student = await _firestore.getStudent(studentId);
    if (student == null) {
      throw Exception('Student not found');
    }

    final marks = await _firestore.getMarksByStudent(studentId);
    final attendance = await _firestore.getAttendanceByStudent(studentId);
    final gpa = await _erp.calculateSemesterGPA(
      studentId,
      student.year,
      student.semester,
    );
    final cgpa = await _erp.calculateCGPA(studentId, student.semester);
    final attPct = await _erp.getOverallAttendancePercentage(
      studentId,
      student.year,
      student.semester,
    );

    return ReportCardData(
      student: student,
      marks: marks,
      attendance: attendance,
      gpa: gpa,
      cgpa: cgpa,
      attendancePercentage: attPct,
    );
  }

  String generateTranscriptText(ReportCardData data) {
    final buffer = StringBuffer();
    buffer.writeln('ACADEMIC TRANSCRIPT');
    buffer.writeln('===================');
    buffer.writeln('Name: ${data.student.name}');
    buffer.writeln('Roll No: ${data.student.rollNo}');
    buffer.writeln('Branch: ${data.student.branch}');
    buffer.writeln('Year: ${data.student.year}  Semester: ${data.student.semester}');
    buffer.writeln('GPA: ${data.gpa.toStringAsFixed(2)}');
    buffer.writeln('CGPA: ${data.cgpa.toStringAsFixed(2)}');
    buffer.writeln(
      'Attendance: ${data.attendancePercentage.toStringAsFixed(1)}%',
    );
    buffer.writeln('');
    buffer.writeln('SUBJECT-WISE MARKS');
    buffer.writeln('------------------');
    for (final m in data.marks) {
      buffer.writeln(
        '${m.subjectId}: Internal=${m.internal} External=${m.external} '
        'Total=${m.total} Grade=${m.grade}',
      );
    }
    return buffer.toString();
  }

  String generateReportCardText(ReportCardData data) {
    final buffer = StringBuffer();
    buffer.writeln('REPORT CARD');
    buffer.writeln('===========');
    buffer.writeln('Student: ${data.student.name}');
    buffer.writeln('Roll: ${data.student.rollNo}');
    buffer.writeln('Semester GPA: ${data.gpa.toStringAsFixed(2)}');
    buffer.writeln('CGPA: ${data.cgpa.toStringAsFixed(2)}');
    buffer.writeln(
      'Attendance: ${data.attendancePercentage.toStringAsFixed(1)}%',
    );
    buffer.writeln('');
    for (final m in data.marks) {
      buffer.writeln('${m.subjectId}: ${m.total}/100 (${m.grade})');
      if (m.remark.isNotEmpty) buffer.writeln('  Remark: ${m.remark}');
    }
    return buffer.toString();
  }
}
