/// Attendance document in `attendance` collection.
///
/// Fields:
/// - id
/// - studentId
/// - subjectId
/// - year
/// - semester
/// - presentClasses
/// - totalClasses
/// - percentage
class AttendanceModel {
  final String id;
  final String studentId;
  final String subjectId;
  final int year;
  final int semester;
  final int presentClasses;
  final int totalClasses;
  final double percentage;

  AttendanceModel({
    this.id = '',
    required this.studentId,
    required this.subjectId,
    this.year = 1,
    this.semester = 1,
    this.presentClasses = 0,
    this.totalClasses = 0,
    double? percentage,
  }) : percentage =
           percentage ??
           (totalClasses > 0 ? (presentClasses / totalClasses) * 100 : 0.0);

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    final present = (map['presentClasses'] as int?) ?? 0;
    final total = (map['totalClasses'] as int?) ?? 0;
    return AttendanceModel(
      id: (map['id'] as String?) ?? '',
      studentId: (map['studentId'] as String?) ?? '',
      subjectId: (map['subjectId'] as String?) ?? '',
      year: (map['year'] as int?) ?? 1,
      semester: (map['semester'] as int?) ?? 1,
      presentClasses: present,
      totalClasses: total,
      percentage:
          (map['percentage'] as num?)?.toDouble() ??
          (total > 0 ? (present / total) * 100 : 0.0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'studentId': studentId,
      'subjectId': subjectId,
      'year': year,
      'semester': semester,
      'presentClasses': presentClasses,
      'totalClasses': totalClasses,
      'percentage': percentage,
    };
  }
}
