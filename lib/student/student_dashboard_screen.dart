import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../models/marks_model.dart';
import '../models/student_model.dart';
import '../services/auth_service.dart';
import '../services/erp_service.dart';
import '../services/firestore_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _erpService = ERPService();

  bool _isLoading = true;
  String? _error;
  StudentModel? _student;
  List<MarksModel> _marks = const [];
  List<AttendanceModel> _attendance = const [];
  double _semesterGpa = 0.0;
  double _cgpa = 0.0;
  double _attendanceAverage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Not logged in.';
          _marks = const [];
          _attendance = const [];
          _student = null;
        });
        return;
      }

      final student = await _firestoreService.getStudent(user.uid);
      if (student == null) {
        setState(() {
          _error = 'Student record not found.';
          _marks = const [];
          _attendance = const [];
        });
        return;
      }

      final marks = await _firestoreService.getMarksByStudent(user.uid);
      final attendance = await _firestoreService.getAttendanceByStudent(
        user.uid,
      );
      final semesterGpa = await _erpService.calculateSemesterGPA(
        user.uid,
        student.year,
        student.semester,
      );
      final cgpa = await _erpService.calculateCGPA(user.uid, student.semester);
      final attendanceAverage = await _erpService
          .getOverallAttendancePercentage(
            user.uid,
            student.year,
            student.semester,
          );

      setState(() {
        _student = student;
        _marks = marks;
        _attendance = attendance;
        _semesterGpa = semesterGpa;
        _cgpa = cgpa;
        _attendanceAverage = attendanceAverage;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _marks = const [];
        _attendance = const [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_student == null) {
      return const Center(child: Text('Student profile not found.'));
    }

    final subjects = <String>{
      ..._marks.map((m) => m.subjectId),
      ..._attendance.map((a) => a.subjectId),
    }.toList();

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _student!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Email: ${_student!.email}'),
                  Text('Roll No: ${_student!.rollNo}'),
                  Text(
                    'Year ${_student!.year}, Semester ${_student!.semester}',
                  ),
                  Text('Batch: ${_student!.batch}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPerformanceSummary(),
          const SizedBox(height: 12),
          Text(
            'Subject-wise Breakdown',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (subjects.isEmpty)
            const Text('No subject data available yet.')
          else
            ...subjects.map(_buildSubjectCard),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic Performance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildStatRow('Semester GPA', _semesterGpa, maxValue: 10),
            const SizedBox(height: 8),
            _buildStatRow('CGPA', _cgpa, maxValue: 10),
            const SizedBox(height: 8),
            _buildStatRow('Attendance Avg', _attendanceAverage, maxValue: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, double value, {required double maxValue}) {
    final progress = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: ${value.toStringAsFixed(1)}'),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: progress),
      ],
    );
  }

  Widget _buildSubjectCard(String subjectId) {
    final mark = _marks.firstWhere(
      (m) => m.subjectId == subjectId,
      orElse: () => MarksModel(
        studentId: _student!.id,
        subjectId: subjectId,
        internal: 0,
        external: 0,
        total: 0,
      ),
    );

    final attendance = _attendance.firstWhere(
      (a) => a.subjectId == subjectId,
      orElse: () =>
          AttendanceModel(studentId: _student!.id, subjectId: subjectId),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subjectId, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Internal: ${mark.internal}'),
            Text('External: ${mark.external}'),
            Text('Total Marks: ${mark.total}'),
            Text('Percentage: ${mark.percentage.toStringAsFixed(1)}%'),
            Text('Grade: ${mark.grade}'),
            if (mark.remark.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Remark: ${mark.remark}'),
            ],
            const SizedBox(height: 12),
            Text(
              'Attendance: ${attendance.presentClasses}/${attendance.totalClasses}',
            ),
            Text('Attendance %: ${attendance.percentage.toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            _buildStatRow(
              'Subject Attendance',
              attendance.percentage,
              maxValue: 100,
            ),
          ],
        ),
      ),
    );
  }
}
