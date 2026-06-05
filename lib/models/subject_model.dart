/// Subject document in `subjects` collection.
///
/// Fields:
/// - id
/// - name
/// - code (e.g., CS201)
/// - year (1-4)
/// - semester (1-8)
/// - branch
/// - teacherId
/// - credits
/// - maxMarks
class SubjectModel {
  final String id;
  final String name;
  final String code;
  final int year;
  final int semester;
  final String branch;
  final String teacherId;
  final int credits;
  final int maxMarks;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.code,
    this.year = 1,
    this.semester = 1,
    this.branch = 'Computer Engineering',
    required this.teacherId,
    this.credits = 3,
    this.maxMarks = 100,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      code: (map['code'] as String?) ?? '',
      year: (map['year'] as int?) ?? 1,
      semester: (map['semester'] as int?) ?? 1,
      branch: (map['branch'] as String?) ?? 'Computer Engineering',
      teacherId: (map['teacherId'] as String?) ?? '',
      credits: (map['credits'] as int?) ?? 3,
      maxMarks: (map['maxMarks'] as int?) ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'code': code,
      'year': year,
      'semester': semester,
      'branch': branch,
      'teacherId': teacherId,
      'credits': credits,
      'maxMarks': maxMarks,
    };
  }
}
