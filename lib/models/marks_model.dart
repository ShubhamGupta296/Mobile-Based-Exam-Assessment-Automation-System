/// Marks document in `marks` collection.
///
/// Fields:
/// - id (auto-generated)
/// - studentId
/// - subjectId
/// - year (1-4)
/// - semester (1-8)
/// - internal
/// - external
/// - total
/// - percentage
/// - gradePoint (0.0-10.0)
/// - grade (A+, A, B, etc.)
/// - remark
/// - recordedDate
class MarksModel {
  final String id;
  final String studentId;
  final String subjectId;
  final int year;
  final int semester;
  final int internal;
  final int external;
  final int total;
  final double percentage;
  final double gradePoint;
  final String grade;
  final String remark;
  final DateTime recordedDate;

  MarksModel({
    this.id = '',
    required this.studentId,
    required this.subjectId,
    this.year = 1,
    this.semester = 1,
    required this.internal,
    required this.external,
    required this.total,
    this.percentage = 0.0,
    this.gradePoint = 0.0,
    this.grade = 'F',
    this.remark = '',
    DateTime? recordedDate,
  }) : recordedDate = recordedDate ?? DateTime.now();

  factory MarksModel.fromMap(Map<String, dynamic> map) {
    return MarksModel(
      id: (map['id'] as String?) ?? '',
      studentId: (map['studentId'] as String?) ?? '',
      subjectId: (map['subjectId'] as String?) ?? '',
      year: (map['year'] as int?) ?? 1,
      semester: (map['semester'] as int?) ?? 1,
      internal: (map['internal'] as int?) ?? 0,
      external: (map['external'] as int?) ?? 0,
      total: (map['total'] as int?) ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      gradePoint: (map['gradePoint'] as num?)?.toDouble() ?? 0.0,
      grade: (map['grade'] as String?) ?? 'F',
      remark: (map['remark'] as String?) ?? '',
      recordedDate: map['recordedDate'] is DateTime
          ? map['recordedDate']
          : DateTime.tryParse(map['recordedDate'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'studentId': studentId,
      'subjectId': subjectId,
      'year': year,
      'semester': semester,
      'internal': internal,
      'external': external,
      'total': total,
      'percentage': percentage,
      'gradePoint': gradePoint,
      'grade': grade,
      'remark': remark,
      'recordedDate': recordedDate.toIso8601String(),
    };
  }

  /// Calculate percentage from internal and external marks (out of 100)
  static double calculatePercentage(int internal, int external) {
    return ((internal + external) / 100) * 100;
  }

  /// Calculate grade point from total marks (out of 100)
  static double calculateGradePoint(int total) {
    if (total >= 90) return 10.0;
    if (total >= 80) return 9.0;
    if (total >= 70) return 8.0;
    if (total >= 60) return 7.0;
    if (total >= 50) return 6.0;
    if (total >= 40) return 5.0;
    return 0.0;
  }

  /// Get letter grade from total marks
  static String getGrade(int total) {
    if (total >= 90) return 'A+';
    if (total >= 80) return 'A';
    if (total >= 70) return 'B';
    if (total >= 60) return 'C';
    if (total >= 50) return 'D';
    if (total >= 40) return 'E';
    return 'F';
  }
}
