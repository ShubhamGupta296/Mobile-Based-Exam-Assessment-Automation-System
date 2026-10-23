import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../models/daily_attendance_model.dart';
import '../models/marks_model.dart';
import '../models/student_model.dart';
import '../services/auth_service.dart';
import '../services/erp_service.dart';
import '../services/firestore_service.dart';
import '../widgets/attendance_health_badge.dart';
import '../widgets/logout_button.dart';

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
  List<DailyAttendanceModel> _dailyLogs = const [];
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
          _dailyLogs = const [];
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
          _dailyLogs = const [];
        });
        return;
      }

      final marks = await _firestoreService.getMarksByStudent(user.uid);
      final attendance = await _firestoreService.getAttendanceByStudent(
        user.uid,
      );
      final dailyLogs = await _firestoreService.getDailyAttendanceByStudent(
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

      if (!mounted) return;
      setState(() {
        _student = student;
        _marks = marks;
        _attendance = attendance;
        _dailyLogs = dailyLogs;
        _semesterGpa = semesterGpa;
        _cgpa = cgpa;
        _attendanceAverage = attendanceAverage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _marks = const [];
        _attendance = const [];
        _dailyLogs = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: const [LogoutButton()],
      ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _student!.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AttendanceHealthBadge(percentage: _attendanceAverage),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Email: ${_student!.email}'),
                  Text('Roll No: ${_student!.rollNo} • Div ${_student!.division}'),
                  Text(
                    'Year ${_student!.year}, Semester ${_student!.semester} (${_student!.branch})',
                  ),
                ],
              ),
            ),
          ),
          if (_attendanceAverage < 75.0 && _attendance.isNotEmpty)
            Card(
              color: Colors.red.shade50,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Low Attendance Warning: Your overall attendance is ${_attendanceAverage.toStringAsFixed(1)}%. Minimum 75% required for exam eligibility.',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          _buildPerformanceSummary(),
          const SizedBox(height: 12),
          Text(
            'Subject Breakdown & Attendance History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              'Academic Performance Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Semester GPA', _semesterGpa, maxValue: 10),
            const SizedBox(height: 8),
            _buildStatRow('CGPA', _cgpa, maxValue: 10),
            const SizedBox(height: 8),
            _buildStatRow('Overall Attendance Avg', _attendanceAverage, maxValue: 100),
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

    final subjectDailyLogs = _dailyLogs.where((l) => l.subjectId == subjectId).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(subjectId, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Total Marks: ${mark.total} • Grade: ${mark.grade} • Attendance: ${attendance.percentage.toStringAsFixed(1)}%',
        ),
        trailing: AttendanceHealthBadge(percentage: attendance.percentage),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Internal Marks: ${mark.internal}/30'),
                    Text('External Marks: ${mark.external}/70'),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Grade Point: ${mark.gradePoint}'),
                if (mark.remark.isNotEmpty) Text('Remark: ${mark.remark}'),
                const Divider(height: 16),
                Text(
                  'Classes Attended: ${attendance.presentClasses} / ${attendance.totalClasses}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStatRow('Subject Attendance', attendance.percentage, maxValue: 100),
                const SizedBox(height: 12),
                Text(
                  'Recent Lecture Log:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                if (subjectDailyLogs.isEmpty)
                  const Text('No individual lecture logs recorded yet.')
                else
                  Column(
                    children: subjectDailyLogs.take(5).map((log) {
                      final isPresent = log.presentStudentIds.contains(_student!.id);
                      final dateStr = '${log.date.day}/${log.date.month}/${log.date.year}';
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Lec ${log.lectureNumber} • $dateStr', style: const TextStyle(fontSize: 12)),
                            Text(
                              isPresent ? 'PRESENT' : 'ABSENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
