import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/attendance_model.dart';
import '../models/department_model.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../models/marks_model.dart';

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
    await _db.collection('users').doc(uid).update({
      'approvalStatus': status,
    });
  }

  Future<int> deleteAllStudents() async {
    final snapshot = await _db.collection('students').get();
    if (snapshot.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  Future<int> deleteUsersByRoles(List<String> roles) async {
    if (roles.isEmpty) return 0;

    final snapshot = await _db
        .collection('users')
        .where('role', whereIn: roles)
        .get();
    if (snapshot.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snapshot.docs.length;
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
    await _db
        .collection('students')
        .doc(student.id)
        .update(student.toMap());
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
