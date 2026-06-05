/// Student Performance Analytics.
///
/// Fields:
/// - studentId
/// - semester
/// - year
/// - averageMarks
/// - gpa
/// - attendancePercentage
/// - strengths (list of subject names)
/// - weaknesses (list of subject names)
/// - overallRank
class PerformanceModel {
  final String studentId;
  final int semester;
  final int year;
  final double averageMarks;
  final double gpa;
  final double attendancePercentage;
  final List<String> strengths;
  final List<String> weaknesses;
  final int? overallRank;

  const PerformanceModel({
    required this.studentId,
    required this.semester,
    required this.year,
    required this.averageMarks,
    required this.gpa,
    required this.attendancePercentage,
    this.strengths = const [],
    this.weaknesses = const [],
    this.overallRank,
  });

  factory PerformanceModel.fromMap(Map<String, dynamic> map) {
    return PerformanceModel(
      studentId: (map['studentId'] as String?) ?? '',
      semester: (map['semester'] as int?) ?? 1,
      year: (map['year'] as int?) ?? 1,
      averageMarks: (map['averageMarks'] as num?)?.toDouble() ?? 0.0,
      gpa: (map['gpa'] as num?)?.toDouble() ?? 0.0,
      attendancePercentage:
          (map['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      strengths: List<String>.from(map['strengths'] as List? ?? []),
      weaknesses: List<String>.from(map['weaknesses'] as List? ?? []),
      overallRank: map['overallRank'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentId': studentId,
      'semester': semester,
      'year': year,
      'averageMarks': averageMarks,
      'gpa': gpa,
      'attendancePercentage': attendancePercentage,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'overallRank': overallRank,
    };
  }
}
