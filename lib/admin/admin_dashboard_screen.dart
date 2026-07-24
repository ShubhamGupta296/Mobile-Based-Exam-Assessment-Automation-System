import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/department_model.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../services/firestore_service.dart';
import '../services/subject_assignment_service.dart';
import '../widgets/logout_button.dart';
import 'admin_analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirestoreService();
  final _subjectService = SubjectAssignmentService();

  late TabController _tabController;

  bool _loading = true;
  String? _statusMessage;
  bool _resultLocked = false;
  bool _isPublishing = false;

  Map<String, int> _stats = {};
  List<StudentModel> _students = [];
  List<UserModel> _teachers = [];
  List<SubjectModel> _subjects = [];
  List<DepartmentModel> _departments = [];
  List<UserModel> _pendingUsers = [];

  String _studentSearch = '';
  String _teacherSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final stats = await _firestore.getAdminStats();
      final students = await _firestore.getAllStudents();
      final teachers = await _firestore.getUsersByRole('teacher');
      final subjects = await _firestore.getAllSubjects();
      final departments = await _firestore.getAllDepartments();
      final pending = await _firestore.getPendingRegistrations();
      final locked = await _firestore.isResultLocked();

      setState(() {
        _stats = stats;
        _students = students;
        _teachers = teachers;
        _subjects = subjects;
        _departments = departments;
        _pendingUsers = pending;
        _resultLocked = locked;
      });
    } catch (e) {
      setState(() => _statusMessage = 'Load error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<StudentModel> get _filteredStudents {
    if (_studentSearch.isEmpty) return _students;
    final q = _studentSearch.toLowerCase();
    return _students
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.rollNo.toLowerCase().contains(q) ||
              s.email.toLowerCase().contains(q),
        )
        .toList();
  }

  List<UserModel> get _filteredTeachers {
    if (_teacherSearch.isEmpty) return _teachers;
    final q = _teacherSearch.toLowerCase();
    return _teachers
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              t.email.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _publishResult() async {
    setState(() => _isPublishing = true);
    try {
      await _firestore.setResultLocked(true);
      setState(() {
        _resultLocked = true;
        _statusMessage = 'Result published. Marks are now locked.';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Publish error: $e');
    } finally {
      setState(() => _isPublishing = false);
    }
  }

  Future<void> _backupCurrentFirestoreSnapshot() async {
    try {
      final backupId = await _firestore.backupCurrentFirestoreSnapshot();
      setState(() => _statusMessage = 'Backup created successfully: $backupId');
    } catch (e) {
      setState(() => _statusMessage = 'Backup failed: $e');
    }
  }

  Future<void> _restoreLatestFirestoreBackup() async {
    try {
      final restoredCount = await _firestore.restoreLatestBackupSnapshot();
      setState(
        () => _statusMessage =
            'Backup restored successfully. $restoredCount records reloaded.',
      );
      await _loadAll();
    } catch (e) {
      setState(() => _statusMessage = 'Restore failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Students'),
            Tab(text: 'Teachers'),
            Tab(text: 'Subjects'),
            Tab(text: 'Departments'),
            Tab(text: 'Registrations'),
            Tab(text: 'Analytics'),
            Tab(text: 'Publish'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
          const LogoutButton(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      _statusMessage!,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _overviewTab(),
                      _studentsTab(),
                      _teachersTab(),
                      _subjectsTab(),
                      _departmentsTab(),
                      _registrationsTab(),
                      const AdminAnalyticsScreen(),
                      _publishTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _overviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statCard('Total Students', _stats['students'] ?? 0, Icons.people),
        _statCard('Total Teachers', _stats['teachers'] ?? 0, Icons.school),
        _statCard('Total Subjects', _stats['subjects'] ?? 0, Icons.book),
        _statCard(
          'Total Departments',
          _stats['departments'] ?? 0,
          Icons.business,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _assignFullCurriculum,
                      child: const Text('Assign Full CE Curriculum'),
                    ),
                    OutlinedButton(
                      onPressed: _backupCurrentFirestoreSnapshot,
                      child: const Text('Backup Current Data'),
                    ),
                    OutlinedButton(
                      onPressed: _restoreLatestFirestoreBackup,
                      child: const Text('Restore Latest Backup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, int value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          '$value',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _assignFullCurriculum() async {
    final teacherId = _teachers.isNotEmpty ? _teachers.first.uid : '';
    if (teacherId.isEmpty) {
      setState(() => _statusMessage = 'Add a teacher first.');
      return;
    }
    try {
      final count = await _subjectService.assignFullCurriculum(
        branch: 'Computer Engineering',
        defaultTeacherId: teacherId,
      );
      setState(() => _statusMessage = 'Assigned $count subjects.');
      await _loadAll();
    } catch (e) {
      setState(() => _statusMessage = 'Assignment error: $e');
    }
  }

  Widget _studentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search students',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _studentSearch = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredStudents.length,
            itemBuilder: (ctx, i) {
              final s = _filteredStudents[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text(
                    'Roll: ${s.rollNo} | Y${s.year} S${s.semester} | ${s.branch}',
                  ),
                  trailing: Text(s.status),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _showAddStudentDialog,
            child: const Text('Add Student'),
          ),
        ),
      ],
    );
  }

  Widget _teachersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search teachers',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _teacherSearch = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredTeachers.length,
            itemBuilder: (ctx, i) {
              final t = _filteredTeachers[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.email} | ${t.approvalStatus}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (role) => _changeRole(t.uid, role),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'teacher', child: Text('Teacher')),
                      PopupMenuItem(value: 'admin', child: Text('Admin')),
                      PopupMenuItem(value: 'student', child: Text('Student')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _changeRole(String uid, String role) async {
    try {
      await _firestore.updateUserRole(uid, role);
      setState(() => _statusMessage = 'Role updated to $role');
      await _loadAll();
    } catch (e) {
      setState(() => _statusMessage = 'Role update error: $e');
    }
  }

  Widget _subjectsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _subjects.length,
            itemBuilder: (ctx, i) {
              final s = _subjects[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text('${s.name} (${s.code})'),
                  subtitle: Text(
                    'Y${s.year} S${s.semester} | Teacher: ${s.teacherId}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditSubjectDialog(s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteSubject(s.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _showAddSubjectDialog,
                  child: const Text('Add Subject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _showAssignSemesterDialog,
                  child: const Text('Assign to Semester'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _departmentsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _departments.length,
            itemBuilder: (ctx, i) {
              final d = _departments[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text('${d.name} (${d.code})'),
                  subtitle: Text(
                    'Head: ${d.headId} | Students: ${d.totalStudents}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteDepartment(d.id),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _showAddDepartmentDialog,
            child: const Text('Add Department'),
          ),
        ),
      ],
    );
  }

  Widget _registrationsTab() {
    if (_pendingUsers.isEmpty) {
      return const Center(child: Text('No pending registrations.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingUsers.length,
      itemBuilder: (ctx, i) {
        final u = _pendingUsers[i];
        return Card(
          child: ListTile(
            title: Text(u.name),
            subtitle: Text('${u.email} | Role: ${u.role}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveUser(u.uid),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectUser(u.uid),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _approveUser(String uid) async {
    await _firestore.updateApprovalStatus(uid, 'approved');
    setState(() => _statusMessage = 'User approved.');
    await _loadAll();
  }

  Future<void> _rejectUser(String uid) async {
    await _firestore.updateApprovalStatus(uid, 'rejected');
    setState(() => _statusMessage = 'User rejected.');
    await _loadAll();
  }

  Widget _publishTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Publish Result',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${_resultLocked ? 'Published (locked)' : 'Editable'}',
              ),
              const SizedBox(height: 16),
              const Text('Once published, teachers cannot edit marks.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _resultLocked || _isPublishing
                    ? null
                    : _publishResult,
                child: Text(
                  _resultLocked
                      ? 'Already Published'
                      : (_isPublishing ? 'Publishing...' : 'Publish Result'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  Future<void> _showAddStudentDialog() async {
    final nameCtrl = TextEditingController();
    final rollCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: rollCtrl,
              decoration: const InputDecoration(labelText: 'Roll No'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final student = StudentModel(
        id: rollCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        rollNo: rollCtrl.text.trim(),
        email: emailCtrl.text.trim(),
      );
      await _firestore.addStudent(student);
      await _loadAll();
    }
    nameCtrl.dispose();
    rollCtrl.dispose();
    emailCtrl.dispose();
  }

  Future<void> _showAddSubjectDialog() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final teacherCtrl = TextEditingController();
    int year = 1;
    int semester = 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Code (e.g. DSA101)',
                  ),
                ),
                TextField(
                  controller: teacherCtrl,
                  decoration: const InputDecoration(labelText: 'Teacher UID'),
                ),
                DropdownButton<int>(
                  value: year,
                  items: List.generate(
                    4,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('Year ${i + 1}'),
                    ),
                  ),
                  onChanged: (v) => setDialogState(() => year = v ?? 1),
                ),
                DropdownButton<int>(
                  value: semester,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Semester 1')),
                    DropdownMenuItem(value: 2, child: Text('Semester 2')),
                  ],
                  onChanged: (v) => setDialogState(() => semester = v ?? 1),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final subject = SubjectModel(
        id: nameCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        code: codeCtrl.text.trim(),
        year: year,
        semester: semester,
        teacherId: teacherCtrl.text.trim(),
      );
      await _firestore.addSubject(subject);
      await _loadAll();
    }
    nameCtrl.dispose();
    codeCtrl.dispose();
    teacherCtrl.dispose();
  }

  Future<void> _showEditSubjectDialog(SubjectModel subject) async {
    final teacherCtrl = TextEditingController(text: subject.teacherId);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${subject.name}'),
        content: TextField(
          controller: teacherCtrl,
          decoration: const InputDecoration(labelText: 'Teacher UID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _subjectService.assignTeacherToSubject(
        subject.id,
        teacherCtrl.text.trim(),
      );
      await _loadAll();
    }
    teacherCtrl.dispose();
  }

  Future<void> _deleteSubject(String id) async {
    await _firestore.deleteSubject(id);
    await _loadAll();
  }

  Future<void> _showAssignSemesterDialog() async {
    int year = 1;
    int semester = 1;
    final teacherCtrl = TextEditingController(
      text: _teachers.isNotEmpty ? _teachers.first.uid : '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Assign CE Subjects'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: year,
                items: List.generate(
                  4,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Year ${i + 1}'),
                  ),
                ),
                onChanged: (v) => setDialogState(() => year = v ?? 1),
              ),
              DropdownButton<int>(
                value: semester,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Semester 1')),
                  DropdownMenuItem(value: 2, child: Text('Semester 2')),
                ],
                onChanged: (v) => setDialogState(() => semester = v ?? 1),
              ),
              TextField(
                controller: teacherCtrl,
                decoration: const InputDecoration(labelText: 'Teacher UID'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await _subjectService.assignSubjectsToYearSemester(
        year: year,
        semester: semester,
        branch: 'Computer Engineering',
        teacherId: teacherCtrl.text.trim(),
      );
      setState(
        () => _statusMessage = 'Subjects assigned for Y$year S$semester',
      );
      await _loadAll();
    }
    teacherCtrl.dispose();
  }

  Future<void> _showAddDepartmentDialog() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final headCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
            TextField(
              controller: headCtrl,
              decoration: const InputDecoration(labelText: 'Head Teacher UID'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final dept = DepartmentModel(
        id: codeCtrl.text.trim().toLowerCase(),
        name: nameCtrl.text.trim(),
        code: codeCtrl.text.trim(),
        headId: headCtrl.text.trim(),
      );
      await _firestore.addDepartment(dept);
      await _loadAll();
    }
    nameCtrl.dispose();
    codeCtrl.dispose();
    headCtrl.dispose();
  }

  Future<void> _deleteDepartment(String id) async {
    await _firestore.deleteDepartment(id);
    await _loadAll();
  }
}
