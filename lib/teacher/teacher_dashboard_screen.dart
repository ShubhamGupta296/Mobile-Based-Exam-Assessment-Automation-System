import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../models/student_model.dart';
import '../models/marks_model.dart';
import '../services/firestore_service.dart';
import '../widgets/logout_button.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  static const List<String> _subjects = [
    'DSA',
    'OOPS',
    'DBMS',
    'CN',
    'OS',
    'TOC',
    'COA',
    'Software Engineering',
    'AI',
  ];

  final _firestoreService = FirestoreService();

  bool _isLoadingStudents = true;
  bool _resultLocked = false;
  bool _isTogglingLock = false;
  String? _loadError;
  List<StudentModel> _students = [];

  final Map<String, TextEditingController> _internalCtrls = {};
  final Map<String, TextEditingController> _externalCtrls = {};
  final Map<String, TextEditingController> _remarkCtrls = {};
  final Map<String, TextEditingController> _presentCtrls = {};
  final Map<String, TextEditingController> _totalClassCtrls = {};
  final Map<String, int> _totals = {};
  final Map<String, double> _attendancePercent = {};
  final Map<String, String> _selectedSubject = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadResultLock();
    await _loadStudents();
  }

  Future<void> _loadResultLock() async {
    final locked = await _firestoreService.isResultLocked();
    setState(() {
      _resultLocked = locked;
    });
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
      _loadError = null;
    });

    try {
      final snapshot = await _firestoreService.db.collection('students').get();
      final students = snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data()))
          .toList(growable: false);

      for (final s in students) {
        _internalCtrls[s.id] = TextEditingController();
        _externalCtrls[s.id] = TextEditingController();
        _remarkCtrls[s.id] = TextEditingController();
        _presentCtrls[s.id] = TextEditingController();
        _totalClassCtrls[s.id] = TextEditingController();
        _totals[s.id] = 0;
        _attendancePercent[s.id] = 0.0;
        _selectedSubject[s.id] = _subjects.first;

        await _loadStudentSubjectData(
          s.id,
          _subjects.first,
          s.year,
          s.semester,
        );
      }

      setState(() {
        _students = students;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _loadStudentSubjectData(
    String studentId,
    String subjectId,
    int year,
    int semester,
  ) async {
    final marks = await _firestoreService.getMarksByStudentAndSubject(
      studentId,
      subjectId,
    );

    final attendance = await _firestoreService.getAttendanceByStudentAndSubject(
      studentId,
      subjectId,
      year,
      semester,
    );

    setState(() {
      if (marks != null) {
        _internalCtrls[studentId]?.text = marks.internal.toString();
        _externalCtrls[studentId]?.text = marks.external.toString();
        _remarkCtrls[studentId]?.text = marks.remark;
        _totals[studentId] = marks.total;
      } else {
        _internalCtrls[studentId]?.clear();
        _externalCtrls[studentId]?.clear();
        _remarkCtrls[studentId]?.clear();
        _totals[studentId] = 0;
      }

      if (attendance != null) {
        _presentCtrls[studentId]?.text = attendance.presentClasses.toString();
        _totalClassCtrls[studentId]?.text = attendance.totalClasses.toString();
        _attendancePercent[studentId] = attendance.percentage;
      } else {
        _presentCtrls[studentId]?.clear();
        _totalClassCtrls[studentId]?.clear();
        _attendancePercent[studentId] = 0.0;
      }
    });
  }

  void _recalculateTotal(String studentId) {
    final internalText = _internalCtrls[studentId]?.text ?? '';
    final externalText = _externalCtrls[studentId]?.text ?? '';
    final internal = int.tryParse(internalText) ?? 0;
    final external = int.tryParse(externalText) ?? 0;
    setState(() {
      _totals[studentId] = internal + external;
    });
  }

  void _recalculateAttendancePercent(String studentId) {
    final present = int.tryParse(_presentCtrls[studentId]?.text ?? '') ?? 0;
    final total = int.tryParse(_totalClassCtrls[studentId]?.text ?? '') ?? 0;
    setState(() {
      _attendancePercent[studentId] = total > 0 ? (present / total) * 100 : 0.0;
    });
  }

  Future<void> _saveMarksForStudent(StudentModel student) async {
    if (_resultLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Results are locked. Marks cannot be edited.'),
        ),
      );
      return;
    }

    final selectedSubject = _selectedSubject[student.id] ?? _subjects.first;
    final internalText = _internalCtrls[student.id]?.text ?? '';
    final externalText = _externalCtrls[student.id]?.text ?? '';
    final remarkText = _remarkCtrls[student.id]?.text ?? '';
    final presentText = _presentCtrls[student.id]?.text ?? '';
    final totalClassesText = _totalClassCtrls[student.id]?.text ?? '';

    final internal = int.tryParse(internalText);
    final external = int.tryParse(externalText);
    final presentClasses = int.tryParse(presentText) ?? 0;
    final totalClasses = int.tryParse(totalClassesText) ?? 0;

    if (internal == null || external == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid marks (numbers).')),
      );
      return;
    }

    if (presentClasses > totalClasses) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Present classes cannot exceed total classes.'),
        ),
      );
      return;
    }

    final total = internal + external;
    final percentage = MarksModel.calculatePercentage(internal, external);
    final gradePoint = MarksModel.calculateGradePoint(total);
    final grade = MarksModel.getGrade(total);

    final marks = MarksModel(
      studentId: student.id,
      subjectId: selectedSubject,
      year: student.year,
      semester: student.semester,
      internal: internal,
      external: external,
      total: total,
      percentage: percentage,
      gradePoint: gradePoint,
      grade: grade,
      remark: remarkText,
    );

    final attendance = AttendanceModel(
      studentId: student.id,
      subjectId: selectedSubject,
      year: student.year,
      semester: student.semester,
      presentClasses: presentClasses,
      totalClasses: totalClasses,
    );

    try {
      await _firestoreService.updateMarksByStudentAndSubject(
        student.id,
        selectedSubject,
        marks,
      );
      await _firestoreService.addOrUpdateAttendanceSummary(attendance);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $selectedSubject data for ${student.name}'),
        ),
      );
      await _loadStudentSubjectData(
        student.id,
        selectedSubject,
        student.year,
        student.semester,
      );
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
    }
  }

  Future<void> _toggleResultLock() async {
    if (_isTogglingLock) return;

    setState(() => _isTogglingLock = true);

    try {
      await _firestoreService.toggleResultLock();
      await _loadResultLock();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _resultLocked
                ? 'Marks locked. Teachers cannot edit.'
                : 'Marks unlocked. Teachers can now edit.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error toggling lock: $e')));
    } finally {
      if (mounted) setState(() => _isTogglingLock = false);
    }
  }

  @override
  void dispose() {
    for (final c in _internalCtrls.values) {
      c.dispose();
    }
    for (final c in _externalCtrls.values) {
      c.dispose();
    }
    for (final c in _remarkCtrls.values) {
      c.dispose();
    }
    for (final c in _presentCtrls.values) {
      c.dispose();
    }
    for (final c in _totalClassCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: const [LogoutButton()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _resultLocked
                        ? 'Result is published. Marks are locked.'
                        : 'Result not published. Marks are editable.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _isTogglingLock ? null : _toggleResultLock,
                  child: Text(_resultLocked ? 'Unlock Marks' : 'Lock Marks'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(child: Text('Error: $_loadError'));
    }
    if (_students.isEmpty) {
      return const Center(child: Text('No students found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final internalCtrl = _internalCtrls[student.id]!;
        final externalCtrl = _externalCtrls[student.id]!;
        final remarkCtrl = _remarkCtrls[student.id]!;
        final total = _totals[student.id] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('Roll No: ${student.rollNo}'),
                const SizedBox(height: 4),
                Text('Year ${student.year}, Semester ${student.semester}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSubject[student.id],
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        items: _subjects
                            .map(
                              (subject) => DropdownMenuItem(
                                value: subject,
                                child: Text(subject),
                              ),
                            )
                            .toList(),
                        onChanged: _resultLocked
                            ? null
                            : (value) async {
                                final subject = value ?? _subjects.first;
                                setState(() {
                                  _selectedSubject[student.id] = subject;
                                });
                                await _loadStudentSubjectData(
                                  student.id,
                                  subject,
                                  student.year,
                                  student.semester,
                                );
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: internalCtrl,
                        enabled: !_resultLocked,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Internal',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _recalculateTotal(student.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: externalCtrl,
                        enabled: !_resultLocked,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'External',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _recalculateTotal(student.id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _presentCtrls[student.id],
                        enabled: !_resultLocked,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Present Classes',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) =>
                            _recalculateAttendancePercent(student.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _totalClassCtrls[student.id],
                        enabled: !_resultLocked,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Classes',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) =>
                            _recalculateAttendancePercent(student.id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Attendance: ${_attendancePercent[student.id]?.toStringAsFixed(1) ?? '0.0'}%',
                ),
                const SizedBox(height: 8),
                Text('Total Marks: $total'),
                const SizedBox(height: 8),
                TextField(
                  controller: remarkCtrl,
                  enabled: !_resultLocked,
                  decoration: const InputDecoration(
                    labelText: 'Remark (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _resultLocked
                        ? null
                        : () => _saveMarksForStudent(student),
                    child: const Text('Save Subject Data'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
