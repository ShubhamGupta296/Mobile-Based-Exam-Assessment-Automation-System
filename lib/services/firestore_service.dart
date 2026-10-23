import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/attendance_model.dart';
import '../models/daily_attendance_model.dart';
import '../models/department_model.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../models/marks_model.dart';
import 'subject_assignment_service.dart';

/// Simple wrapper around FirebaseFirestore for common operations.
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  // Expose the underlying Firestore instance when you need more
  // advanced queries that are not wrapped yet.
  FirebaseFirestore get db => _db;

  /// USERS COLLECTION ---------------------------------------------------------

  Future<void> addUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: role)
        .get();
    return snap.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<List<UserModel>> getPendingRegistrations() async {
    final snap = await _db
        .collection('users')
        .where('approvalStatus', isEqualTo: 'pending')
        .get();
    return snap.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }

  Future<void> updateApprovalStatus(String uid, String status) async {
    await _db.collection('users').doc(uid).update({'approvalStatus': status});
  }

  /// STUDENTS COLLECTION ------------------------------------------------------

  Future<void> addStudent(StudentModel student) async {
    // Use student.id as document id so it matches the "id" field.
    await _db.collection('students').doc(student.id).set(student.toMap());
  }

  Future<List<StudentModel>> getAllStudents() async {
    final snap = await _db.collection('students').get();
    return snap.docs
        .map((doc) => StudentModel.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<void> updateStudent(StudentModel student) async {
    await _db.collection('students').doc(student.id).update(student.toMap());
  }

  Future<void> deleteStudent(String id) async {
    await _db.collection('students').doc(id).delete();
  }

  Future<StudentModel?> getStudent(String uid) async {
    final doc = await _db.collection('students').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return StudentModel.fromMap(data);
  }

  /// SUBJECTS COLLECTION ------------------------------------------------------

  Future<void> addSubject(SubjectModel subject) async {
    await _db.collection('subjects').doc(subject.id).set(subject.toMap());
  }

  Future<List<SubjectModel>> getAllSubjects() async {
    final snap = await _db.collection('subjects').get();
    return snap.docs
        .map((doc) => SubjectModel.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<List<SubjectModel>> getSubjectsByYearSemester(
    int year,
    int semester,
  ) async {
    final snap = await _db
        .collection('subjects')
        .where('year', isEqualTo: year)
        .where('semester', isEqualTo: semester)
        .get();
    return snap.docs
        .map((doc) => SubjectModel.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _db.collection('subjects').doc(subject.id).update(subject.toMap());
  }

  Future<void> deleteSubject(String id) async {
    await _db.collection('subjects').doc(id).delete();
  }

  /// DEPARTMENTS COLLECTION ---------------------------------------------------

  Future<void> addDepartment(DepartmentModel department) async {
    await _db
        .collection('departments')
        .doc(department.id)
        .set(department.toMap());
  }

  Future<List<DepartmentModel>> getAllDepartments() async {
    final snap = await _db.collection('departments').get();
    return snap.docs
        .map((doc) => DepartmentModel.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<void> updateDepartment(DepartmentModel department) async {
    await _db
        .collection('departments')
        .doc(department.id)
        .update(department.toMap());
  }

  Future<void> deleteDepartment(String id) async {
    await _db.collection('departments').doc(id).delete();
  }

  /// STATS --------------------------------------------------------------------

  Future<Map<String, int>> getAdminStats() async {
    final students = await _db.collection('students').get();
    final teachers = await _db
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .get();
    final subjects = await _db.collection('subjects').get();
    final departments = await _db.collection('departments').get();

    return {
      'students': students.docs.length,
      'teachers': teachers.docs.length,
      'subjects': subjects.docs.length,
      'departments': departments.docs.length,
    };
  }

  /// MARKS COLLECTION ---------------------------------------------------------

  Future<String> addMarks(MarksModel marks) async {
    // Let Firestore generate document id.
    final docRef = await _db.collection('marks').add(marks.toMap());
    return docRef.id;
  }

  Future<List<MarksModel>> getMarksByStudent(String studentId) async {
    final query = await _db
        .collection('marks')
        .where('studentId', isEqualTo: studentId)
        .get();

    return query.docs
        .map((doc) => MarksModel.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<MarksModel?> getMarksByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    final query = await _db
        .collection('marks')
        .where('studentId', isEqualTo: studentId)
        .where('subjectId', isEqualTo: subjectId)
        .get();

    if (query.docs.isEmpty) return null;
    return MarksModel.fromMap(query.docs.first.data());
  }

  /// ATTENDANCE COLLECTION ----------------------------------------------------

  Future<AttendanceModel?> getAttendanceByStudentAndSubject(
    String studentId,
    String subjectId,
    int year,
    int semester,
  ) async {
    final query = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .where('subjectId', isEqualTo: subjectId)
        .where('year', isEqualTo: year)
        .where('semester', isEqualTo: semester)
        .get();

    if (query.docs.isEmpty) return null;
    return AttendanceModel.fromMap(query.docs.first.data());
  }

  Future<List<AttendanceModel>> getAttendanceByStudent(String studentId) async {
    final query = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();

    return query.docs
        .map((doc) => AttendanceModel.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<void> addOrUpdateAttendanceSummary(AttendanceModel attendance) async {
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

  /// DAILY LECTURE ATTENDANCE -------------------------------------------------

  /// Saves a lecture attendance session and auto-recomputes aggregate
  /// attendance summaries in the `attendance` collection.
  Future<void> saveDailyAttendance(DailyAttendanceModel daily) async {
    final docRef = _db.collection('daily_attendance').doc();
    final modelToSave = DailyAttendanceModel(
      id: docRef.id,
      department: daily.department,
      year: daily.year,
      semester: daily.semester,
      division: daily.division,
      subjectId: daily.subjectId,
      teacherId: daily.teacherId,
      date: daily.date,
      lectureNumber: daily.lectureNumber,
      presentStudentIds: daily.presentStudentIds,
      absentStudentIds: daily.absentStudentIds,
      totalStudents: daily.totalStudents,
      createdAt: daily.createdAt,
    );

    await docRef.set(modelToSave.toMap());

    // Auto-recalculate aggregate summaries for all affected students
    await recalculateStudentAttendanceSummaries(
      subjectId: daily.subjectId,
      year: daily.year,
      semester: daily.semester,
      division: daily.division,
    );
  }

  /// Re-computes cumulative `presentClasses` & `totalClasses` for students
  /// from all stored daily lectures for a subject/semester/division.
  Future<void> recalculateStudentAttendanceSummaries({
    required String subjectId,
    required int year,
    required int semester,
    required String division,
  }) async {
    final snap = await _db
        .collection('daily_attendance')
        .where('subjectId', isEqualTo: subjectId)
        .where('semester', isEqualTo: semester)
        .where('division', isEqualTo: division)
        .get();

    final lectures = snap.docs
        .map((doc) => DailyAttendanceModel.fromMap(doc.data(), docId: doc.id))
        .toList();

    if (lectures.isEmpty) return;

    final totalClasses = lectures.length;
    final Map<String, int> presentCounts = {};

    for (final lecture in lectures) {
      for (final studentId in lecture.presentStudentIds) {
        presentCounts[studentId] = (presentCounts[studentId] ?? 0) + 1;
      }
      for (final studentId in lecture.absentStudentIds) {
        presentCounts.putIfAbsent(studentId, () => 0);
      }
    }

    for (final entry in presentCounts.entries) {
      final studentId = entry.key;
      final presentClasses = entry.value;
      final summary = AttendanceModel(
        studentId: studentId,
        subjectId: subjectId,
        year: year,
        semester: semester,
        presentClasses: presentClasses,
        totalClasses: totalClasses,
      );
      await addOrUpdateAttendanceSummary(summary);
    }
  }

  /// Fetches the last N lectures recorded for a specific subject & section.
  Future<List<DailyAttendanceModel>> getRecentLectures({
    required String subjectId,
    required int semester,
    String division = 'A',
    int limit = 5,
  }) async {
    final snap = await _db
        .collection('daily_attendance')
        .where('subjectId', isEqualTo: subjectId)
        .where('semester', isEqualTo: semester)
        .where('division', isEqualTo: division)
        .get();

    final list = snap.docs
        .map((doc) => DailyAttendanceModel.fromMap(doc.data(), docId: doc.id))
        .toList();

    list.sort((a, b) => b.date.compareTo(a.date));
    return list.take(limit).toList();
  }

  /// Fetches all daily attendance records where student was marked present or absent.
  Future<List<DailyAttendanceModel>> getDailyAttendanceByStudent(
    String studentId,
  ) async {
    final snap = await _db.collection('daily_attendance').get();
    final list = snap.docs
        .map((doc) => DailyAttendanceModel.fromMap(doc.data(), docId: doc.id))
        .where(
          (log) =>
              log.presentStudentIds.contains(studentId) ||
              log.absentStudentIds.contains(studentId),
        )
        .toList();

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> updateMarksByStudentAndSubject(
    String studentId,
    String subjectId,
    MarksModel updatedMarks,
  ) async {
    final query = await _db
        .collection('marks')
        .where('studentId', isEqualTo: studentId)
        .where('subjectId', isEqualTo: subjectId)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update(updatedMarks.toMap());
    } else {
      await addMarks(updatedMarks);
    }
  }

  Future<void> deleteMarksByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    final query = await _db
        .collection('marks')
        .where('studentId', isEqualTo: studentId)
        .where('subjectId', isEqualTo: subjectId)
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  /// ADMIN BACKUP / RESTORE ---------------------------------------------------

  /// Create a Firestore snapshot backup of the current account, student, marks,
  /// attendance, and config data. This is admin-only and keeps a safe copy for
  /// later recovery.
  Future<String> backupCurrentFirestoreSnapshot() async {
    final users = await _db.collection('users').get();
    final students = await _db.collection('students').get();
    final subjects = await _db.collection('subjects').get();
    final departments = await _db.collection('departments').get();
    final marks = await _db.collection('marks').get();
    final attendance = await _db.collection('attendance').get();
    final config = await _db.collection('config').get();

    final backupId = 'backup_${DateTime.now().millisecondsSinceEpoch}';
    final snapshot = <String, dynamic>{
      'createdAt': FieldValue.serverTimestamp(),
      'users': users.docs
          .map((doc) => {'__docId': doc.id, ...doc.data()})
          .toList(),
      'students': students.docs
          .map((doc) => {'__docId': doc.id, ...doc.data()})
          .toList(),
      'subjects': subjects.docs
          .map((doc) => {'__docId': doc.id, ...doc.data()})
          .toList(),
      'departments': departments.docs
          .map((doc) => {'__docId': doc.id, ...doc.data()})
          .toList(),
      'marks': marks.docs
          .map((doc) => {'__docId': doc.id, ...doc.data()})
          .toList(),
      'attendance': attendance.docs
          .map((doc) => {'__docId': doc.id, ...doc.data()})
          .toList(),
      'config': config.docs
          .map((doc) => {'__docId': doc.id, ...doc.data()})
          .toList(),
      'note': 'Automatic backup snapshot created by the admin dashboard',
    };

    await _db.collection('backups').doc(backupId).set(snapshot);
    return backupId;
  }

  /// Restore the most recent backup snapshot into the live collections.
  /// This preserves users, students, marks, attendance, and config data safely
  /// by writing them back into the expected collection paths.
  Future<int> restoreLatestBackupSnapshot() async {
    final backupQuery = await _db
        .collection('backups')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (backupQuery.docs.isEmpty) {
      throw Exception('No Firestore backup snapshot is available yet.');
    }

    final backupDoc = backupQuery.docs.first;
    final data = backupDoc.data();
    final batch = _db.batch();

    final users = (data['users'] as List?) ?? const <dynamic>[];
    final students = (data['students'] as List?) ?? const <dynamic>[];
    final subjects = (data['subjects'] as List?) ?? const <dynamic>[];
    final departments = (data['departments'] as List?) ?? const <dynamic>[];
    final marks = (data['marks'] as List?) ?? const <dynamic>[];
    final attendance = (data['attendance'] as List?) ?? const <dynamic>[];
    final config = (data['config'] as List?) ?? const <dynamic>[];

    for (final item in users) {
      final map = Map<String, dynamic>.from(item as Map);
      final docId =
          map.remove('__docId') as String? ?? map['uid'] as String? ?? '';
      batch.set(
        _db.collection('users').doc(docId),
        map,
        SetOptions(merge: true),
      );
    }

    for (final item in students) {
      final map = Map<String, dynamic>.from(item as Map);
      final docId =
          map.remove('__docId') as String? ?? map['id'] as String? ?? '';
      batch.set(
        _db.collection('students').doc(docId),
        map,
        SetOptions(merge: true),
      );
    }

    for (final item in subjects) {
      final map = Map<String, dynamic>.from(item as Map);
      final docId =
          map.remove('__docId') as String? ?? map['id'] as String? ?? '';
      batch.set(
        _db.collection('subjects').doc(docId),
        map,
        SetOptions(merge: true),
      );
    }

    for (final item in departments) {
      final map = Map<String, dynamic>.from(item as Map);
      final docId =
          map.remove('__docId') as String? ?? map['id'] as String? ?? '';
      batch.set(
        _db.collection('departments').doc(docId),
        map,
        SetOptions(merge: true),
      );
    }

    for (final item in marks) {
      final map = Map<String, dynamic>.from(item as Map);
      final docId = map.remove('__docId') as String? ?? '';
      if (docId.isEmpty) {
        batch.set(_db.collection('marks').doc(), map);
      } else {
        batch.set(
          _db.collection('marks').doc(docId),
          map,
          SetOptions(merge: true),
        );
      }
    }

    for (final item in attendance) {
      final map = Map<String, dynamic>.from(item as Map);
      final docId = map.remove('__docId') as String? ?? '';
      if (docId.isEmpty) {
        batch.set(_db.collection('attendance').doc(), map);
      } else {
        batch.set(
          _db.collection('attendance').doc(docId),
          map,
          SetOptions(merge: true),
        );
      }
    }

    for (final item in config) {
      final map = Map<String, dynamic>.from(item as Map);
      final docId = map.remove('__docId') as String? ?? '';
      if (docId.isEmpty) {
        batch.set(_db.collection('config').doc(), map);
      } else {
        batch.set(
          _db.collection('config').doc(docId),
          map,
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();

    return users.length +
        students.length +
        subjects.length +
        departments.length +
        marks.length +
        attendance.length +
        config.length;
  }

  /// RECOVERY / SEEDING ------------------------------------------------------

  /// Rebuild the default structural collections if they were accidentally
  /// removed. This is safe to call on app startup because it only writes the
  /// documents needed for the application to function again.
  Future<void> restoreDefaultCollectionStructure({
    String branch = 'Computer Engineering',
    String defaultTeacherId = '',
  }) async {
    final batch = _db.batch();

    final departmentRef = _db
        .collection('departments')
        .doc('computer-engineering');
    final departmentSnapshot = await departmentRef.get();
    if (!departmentSnapshot.exists) {
      batch.set(
        departmentRef,
        DepartmentModel(
          id: 'computer-engineering',
          name: 'Computer Engineering',
          code: 'CE',
          headId: defaultTeacherId,
        ).toMap(),
      );
    }

    final subjectsSnapshot = await _db.collection('subjects').limit(1).get();
    if (subjectsSnapshot.docs.isEmpty) {
      for (var year = 1; year <= 4; year++) {
        for (var semester = 1; semester <= 2; semester++) {
          final templates = SubjectAssignmentService.subjectsForYearSemester(
            year,
            semester,
          );

          for (final template in templates) {
            final subject = SubjectModel(
              id: template['id']!,
              name: template['name']!,
              code: template['code']!,
              year: year,
              semester: semester,
              branch: branch,
              teacherId: defaultTeacherId,
            );

            batch.set(
              _db.collection('subjects').doc(subject.id),
              subject.toMap(),
            );
          }
        }
      }
    }

    batch.set(_db.collection('config').doc('result'), <String, dynamic>{
      'resultLocked': false,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// CONFIG / SETTINGS --------------------------------------------------------

  /// Store result lock under: config/result (document)
  /// Field: resultLocked (bool)
  Future<void> setResultLocked(bool locked) async {
    await _db.collection('config').doc('result').set(<String, dynamic>{
      'resultLocked': locked,
    }, SetOptions(merge: true));
  }

  Future<bool> isResultLocked() async {
    final doc = await _db.collection('config').doc('result').get();
    final data = doc.data();
    if (data == null) return false;
    final value = data['resultLocked'];
    if (value is bool) return value;
    return false;
  }

  Future<void> toggleResultLock() async {
    final currentLock = await isResultLocked();
    await setResultLocked(!currentLock);
  }
}
