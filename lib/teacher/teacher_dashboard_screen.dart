import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../models/daily_attendance_model.dart';
import '../models/marks_model.dart';
import '../models/student_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/widgets.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> _departments = [
    'Computer Engineering',
    'Information Technology',
    'Electronics',
  ];

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

  static const List<String> _divisions = ['A', 'B', 'C'];
  static const List<int> _semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  final _firestoreService = FirestoreService();

  late TabController _tabController;

  // Filter Selection State
  String _selectedDepartment = _departments.first;
  int _selectedSemester = 1;
  String _selectedDivision = _divisions.first;
  String _selectedSubject = _subjects.first;
  DateTime _selectedDate = DateTime.now();
  int _selectedLectureNumber = 1;

  bool _isLoadingStudents = true;
  bool _isSavingAttendance = false;
  bool _resultLocked = false;
  bool _isTogglingLock = false;
  String? _loadError;

  List<StudentModel> _students = [];
  List<DailyAttendanceModel> _recentLectures = [];

  // Checkbox State for Attendance
  final Map<String, bool> _attendanceCheckbox = {};

  // Marks Form Controllers
  final Map<String, TextEditingController> _internalCtrls = {};
  final Map<String, TextEditingController> _externalCtrls = {};
  final Map<String, TextEditingController> _remarkCtrls = {};
  final Map<String, int> _totals = {};
  final Map<String, AttendanceModel> _attendanceSummaries = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    await _loadResultLock();
    await _loadSectionData();
  }

  Future<void> _loadResultLock() async {
    final locked = await _firestoreService.isResultLocked();
    if (!mounted) return;
    setState(() {
      _resultLocked = locked;
    });
  }

  Future<void> _loadSectionData() async {
    setState(() {
      _isLoadingStudents = true;
      _loadError = null;
    });

    try {
      final snapshot = await _firestoreService.db.collection('students').get();
      final allStudents = snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data()))
          .toList();

      // Filter students by Department/Branch, Semester, Division
      final filtered = allStudents.where((s) {
        final matchesBranch = s.branch == _selectedDepartment ||
            _selectedDepartment == 'Computer Engineering';
        final matchesSem = s.semester == _selectedSemester;
        final matchesDiv = s.division == _selectedDivision;
        return matchesBranch && matchesSem && matchesDiv;
      }).toList();

      // If no exact section match, fallback to semester match
      final targetStudents = filtered.isNotEmpty
          ? filtered
          : allStudents
              .where((s) => s.semester == _selectedSemester)
              .toList();

      _students = targetStudents.isNotEmpty ? targetStudents : allStudents;

      // Initialize Controllers and Checkboxes
      for (final s in _students) {
        _attendanceCheckbox[s.id] = true; // Default Present
        _internalCtrls[s.id] ??= TextEditingController();
        _externalCtrls[s.id] ??= TextEditingController();
        _remarkCtrls[s.id] ??= TextEditingController();
        _totals[s.id] = 0;

        await _loadStudentMarksAndSummary(s.id);
      }

      // Load Recent Lectures History
      final lectures = await _firestoreService.getRecentLectures(
        subjectId: _selectedSubject,
        semester: _selectedSemester,
        division: _selectedDivision,
        limit: 5,
      );

      if (!mounted) return;
      setState(() {
        _recentLectures = lectures;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    }
  }

  Future<void> _loadStudentMarksAndSummary(String studentId) async {
    final year = (_selectedSemester + 1) ~/ 2;

    final marks = await _firestoreService.getMarksByStudentAndSubject(
      studentId,
      _selectedSubject,
    );

    final summary = await _firestoreService.getAttendanceByStudentAndSubject(
      studentId,
      _selectedSubject,
      year,
      _selectedSemester,
    );

    if (!mounted) return;
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

      if (summary != null) {
        _attendanceSummaries[studentId] = summary;
      } else {
        _attendanceSummaries[studentId] = AttendanceModel(
          studentId: studentId,
          subjectId: _selectedSubject,
          year: year,
          semester: _selectedSemester,
        );
      }
    });
  }

  void _markAll(bool present) {
    setState(() {
      for (final s in _students) {
        _attendanceCheckbox[s.id] = present;
      }
    });
  }

  Future<void> _saveDailyAttendance() async {
    if (_isSavingAttendance) return;

    final year = (_selectedSemester + 1) ~/ 2;
    final presentIds = <String>[];
    final absentIds = <String>[];

    for (final student in _students) {
      final isPresent = _attendanceCheckbox[student.id] ?? true;
      if (isPresent) {
        presentIds.add(student.id);
      } else {
        absentIds.add(student.id);
      }
    }

    final dailyRecord = DailyAttendanceModel(
      department: _selectedDepartment,
      year: year,
      semester: _selectedSemester,
      division: _selectedDivision,
      subjectId: _selectedSubject,
      date: _selectedDate,
      lectureNumber: _selectedLectureNumber,
      presentStudentIds: presentIds,
      absentStudentIds: absentIds,
    );

    setState(() => _isSavingAttendance = true);

    try {
      await _firestoreService.saveDailyAttendance(dailyRecord);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved Lecture $_selectedLectureNumber attendance for $_selectedSubject (Div $_selectedDivision)',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      // Reload updated section summaries & lecture history
      await _loadSectionData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving attendance: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSavingAttendance = false);
    }
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

  Future<void> _saveMarksForStudent(StudentModel student) async {
    if (_resultLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Results are locked. Marks cannot be edited.'),
        ),
      );
      return;
    }

    final internalText = _internalCtrls[student.id]?.text ?? '';
    final externalText = _externalCtrls[student.id]?.text ?? '';
    final remarkText = _remarkCtrls[student.id]?.text ?? '';

    final internal = int.tryParse(internalText);
    final external = int.tryParse(externalText);

    if (internal == null || external == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid marks (numbers).')),
      );
      return;
    }

    final total = internal + external;
    final percentage = MarksModel.calculatePercentage(internal, external);
    final gradePoint = MarksModel.calculateGradePoint(total);
    final grade = MarksModel.getGrade(total);

    final year = (_selectedSemester + 1) ~/ 2;

    final marks = MarksModel(
      studentId: student.id,
      subjectId: _selectedSubject,
      year: year,
      semester: _selectedSemester,
      internal: internal,
      external: external,
      total: total,
      percentage: percentage,
      gradePoint: gradePoint,
      grade: grade,
      remark: remarkText,
    );

    try {
      final user = AuthService().currentUser;
      final teacherIdentifier = user?.email ?? user?.uid ?? 'Teacher';

      await _firestoreService.updateMarksWithAudit(
        studentId: student.id,
        subjectId: _selectedSubject,
        updatedMarks: marks,
        performedBy: teacherIdentifier,
        role: 'teacher',
        studentRollNo: student.rollNo,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $_selectedSubject marks for ${student.name} with audit log'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      await _loadStudentMarksAndSummary(student.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving marks: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling lock: $e')),
      );
    } finally {
      if (mounted) setState(() => _isTogglingLock = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _internalCtrls.values) {
      c.dispose();
    }
    for (final c in _externalCtrls.values) {
      c.dispose();
    }
    for (final c in _remarkCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent),
            tooltip: 'Defaulters List (<75%)',
            onPressed: () => DefaulterListDialog.show(
              context,
              department: _selectedDepartment,
              semester: _selectedSemester,
              division: _selectedDivision,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadSectionData,
          ),
          const LogoutButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.check_box_outlined), text: 'Daily Attendance'),
            Tab(icon: Icon(Icons.grade_outlined), text: 'Subject Marks'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterHeader(),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAttendanceTab(),
                _buildMarksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    final monthStr = _monthNames[(_selectedDate.month - 1).clamp(0, 11)];
    final dateStr = '$monthStr ${_selectedDate.day.toString().padLeft(2, '0')}, ${_selectedDate.year}';

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: _departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _selectedDepartment = val);
                    _loadSectionData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedSemester,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: _semesters
                      .map((s) => DropdownMenuItem(value: s, child: Text('Sem $s')))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _selectedSemester = val);
                    _loadSectionData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDivision,
                  decoration: const InputDecoration(
                    labelText: 'Division',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: _divisions
                      .map((div) => DropdownMenuItem(value: div, child: Text('Div $div')))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _selectedDivision = val);
                    _loadSectionData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: _subjects
                      .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _selectedSubject = val);
                    _loadSectionData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(dateStr, style: const TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedLectureNumber,
                  decoration: const InputDecoration(
                    labelText: 'Lec #',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: List.generate(10, (i) => i + 1)
                      .map((lecNum) => DropdownMenuItem(value: lecNum, child: Text('Lec $lecNum')))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _selectedLectureNumber = val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(child: Text('Error: $_loadError'));
    }
    if (_students.isEmpty) {
      return const Center(child: Text('No students found for selected section.'));
    }

    final presentCount = _attendanceCheckbox.values.where((v) => v).length;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        LectureHistoryWidget(
          lectures: _recentLectures,
          onRefresh: _loadSectionData,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Present: $presentCount / ${_students.length}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.check_box, size: 18),
                      label: const Text('Mark All'),
                      onPressed: () => _markAll(true),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.check_box_outline_blank, size: 18),
                      label: const Text('Clear All'),
                      onPressed: () => _markAll(false),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._students.map((student) {
          final isPresent = _attendanceCheckbox[student.id] ?? true;
          final summary = _attendanceSummaries[student.id];
          final pct = summary?.percentage ?? 0.0;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: CheckboxListTile(
              value: isPresent,
              onChanged: (val) {
                setState(() {
                  _attendanceCheckbox[student.id] = val ?? false;
                });
              },
              title: Text(
                student.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Roll: ${student.rollNo} • Cumulative: ${summary?.presentClasses ?? 0}/${summary?.totalClasses ?? 0} classes',
              ),
              secondary: AttendanceHealthBadge(percentage: pct),
            ),
          );
        }),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          icon: _isSavingAttendance
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(
            _isSavingAttendance
                ? 'Saving Attendance...'
                : 'Save Lecture $_selectedLectureNumber Attendance',
            style: const TextStyle(fontSize: 16),
          ),
          onPressed: _isSavingAttendance ? null : _saveDailyAttendance,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMarksTab() {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_students.isEmpty) {
      return const Center(child: Text('No students found for selected section.'));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _resultLocked
                      ? 'Results Published. Marks Locked.'
                      : 'Results Open. Marks Editable.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _resultLocked ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _resultLocked
                          ? null
                          : () async {
                              final user = AuthService().currentUser;
                              await BulkCsvImportDialog.showMarksImport(
                                context,
                                subjectId: _selectedSubject,
                                semester: _selectedSemester,
                                teacherUidOrEmail: user?.email ?? user?.uid ?? 'Teacher',
                              );
                              await _loadSectionData();
                            },
                      icon: const Icon(Icons.table_view, size: 18),
                      label: const Text('Bulk CSV Marks'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _isTogglingLock ? null : _toggleResultLock,
                      child: Text(_resultLocked ? 'Unlock Marks' : 'Lock Marks'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._students.map((student) {
          final internalCtrl = _internalCtrls[student.id]!;
          final externalCtrl = _externalCtrls[student.id]!;
          final remarkCtrl = _remarkCtrls[student.id]!;
          final total = _totals[student.id] ?? 0;
          final summary = _attendanceSummaries[student.id];

          return Card(
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
                        student.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (summary != null)
                        AttendanceHealthBadge(percentage: summary.percentage),
                    ],
                  ),
                  Text('Roll No: ${student.rollNo} • Div ${student.division}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: internalCtrl,
                          enabled: !_resultLocked,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Internal Marks (/30)',
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
                            labelText: 'External Marks (/70)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _recalculateTotal(student.id),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Marks: $total / 100',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                      child: Text('Save $_selectedSubject Marks'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
