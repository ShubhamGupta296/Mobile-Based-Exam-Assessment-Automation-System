import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subject_model.dart';

/// Subject Assignment Service for Computer Engineering curriculum.
///
/// Subject IDs match Teacher Dashboard subject names (e.g. "DSA", "OOPS")
/// so marks/attendance records stay compatible.
class SubjectAssignmentService {
  final FirebaseFirestore _db;

  SubjectAssignmentService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Computer Engineering curriculum: year + semester -> subjects.
  static const Map<String, List<Map<String, String>>> ceCurriculum = {
    '1_1': [
      {'id': 'DSA', 'name': 'DSA', 'code': 'DSA101'},
    ],
    '1_2': [
      {'id': 'OOPS', 'name': 'OOPS', 'code': 'OOPS102'},
    ],
    '2_1': [
      {'id': 'DBMS', 'name': 'DBMS', 'code': 'DBMS201'},
      {'id': 'CN', 'name': 'CN', 'code': 'CN201'},
    ],
    '2_2': [
      {'id': 'OS', 'name': 'OS', 'code': 'OS202'},
    ],
    '3_1': [
      {'id': 'TOC', 'name': 'TOC', 'code': 'TOC301'},
      {'id': 'COA', 'name': 'COA', 'code': 'COA301'},
    ],
    '3_2': [
      {
        'id': 'Software Engineering',
        'name': 'Software Engineering',
        'code': 'SE301',
      },
    ],
    '4_1': [
      {'id': 'AI', 'name': 'AI', 'code': 'AI401'},
      {'id': 'Machine Learning', 'name': 'Machine Learning', 'code': 'ML401'},
    ],
    '4_2': [
      {'id': 'Cloud Computing', 'name': 'Cloud Computing', 'code': 'CC401'},
      {'id': 'Cyber Security', 'name': 'Cyber Security', 'code': 'CS401'},
    ],
  };

  static List<Map<String, String>> subjectsForYearSemester(
    int year,
    int semester,
  ) {
    return ceCurriculum['${year}_$semester'] ?? [];
  }

  static List<String> allSubjectNames() {
    final names = <String>{};
    for (final entry in ceCurriculum.values) {
      for (final subject in entry) {
        names.add(subject['name']!);
      }
    }
    return names.toList()..sort();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> createSubject(SubjectModel subject) async {
    await _db.collection('subjects').doc(subject.id).set(subject.toMap());
  }

  Future<SubjectModel?> getSubject(String id) async {
    final doc = await _db.collection('subjects').doc(id).get();
    if (!doc.exists) return null;
    return SubjectModel.fromMap(doc.data()!);
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _db.collection('subjects').doc(subject.id).update(subject.toMap());
  }

  Future<void> deleteSubject(String id) async {
    await _db.collection('subjects').doc(id).delete();
  }

  Future<List<SubjectModel>> getAllSubjects() async {
    final snap = await _db.collection('subjects').get();
    return snap.docs
        .map((doc) => SubjectModel.fromMap(doc.data()))
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Assignment queries
  // ---------------------------------------------------------------------------

  /// Subjects for a given year and semester (student view).
  Future<List<SubjectModel>> getSubjectsForSemester(
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

  /// Subjects assigned to a teacher (teacher view).
  Future<List<SubjectModel>> getSubjectsByTeacher(String teacherId) async {
    final snap = await _db
        .collection('subjects')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    return snap.docs
        .map((doc) => SubjectModel.fromMap(doc.data()))
        .toList(growable: false);
  }

  /// Auto-assign CE curriculum subjects for a year/semester.
  Future<List<SubjectModel>> assignSubjectsToYearSemester({
    required int year,
    required int semester,
    required String branch,
    required String teacherId,
    int credits = 3,
    int maxMarks = 100,
  }) async {
    final templates = subjectsForYearSemester(year, semester);
    final assigned = <SubjectModel>[];

    for (final template in templates) {
      final subject = SubjectModel(
        id: template['id']!,
        name: template['name']!,
        code: template['code']!,
        year: year,
        semester: semester,
        branch: branch,
        teacherId: teacherId,
        credits: credits,
        maxMarks: maxMarks,
      );

      await createSubject(subject);
      assigned.add(subject);
    }

    return assigned;
  }

  /// Bulk assign all 8 semesters of CE curriculum.
  Future<int> assignFullCurriculum({
    required String branch,
    required String defaultTeacherId,
  }) async {
    var count = 0;
    for (var year = 1; year <= 4; year++) {
      for (var semester = 1; semester <= 2; semester++) {
        final subjects = await assignSubjectsToYearSemester(
          year: year,
          semester: semester,
          branch: branch,
          teacherId: defaultTeacherId,
        );
        count += subjects.length;
      }
    }
    return count;
  }

  /// Reassign teacher for a subject.
  Future<void> assignTeacherToSubject(String subjectId, String teacherId) async {
    await _db.collection('subjects').doc(subjectId).update({
      'teacherId': teacherId,
    });
  }
}
