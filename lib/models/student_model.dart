/// Student document in `students` collection.
///
/// Fields:
/// - id (Auth UID)
/// - name
/// - email
/// - rollNo
/// - year (1-4)
/// - semester (1-8)
/// - branch (Computer Engineering)
/// - batch (e.g., 2024)
/// - gpa (current GPA)
/// - cgpa (cumulative GPA)
/// - status (active/inactive)
class StudentModel {
  final String id;
  final String name;
  final String email;
  final String rollNo;
  final int year; // 1-4
  final int semester; // 1-8
  final String branch; // Computer Engineering
  final int batch;
  final double gpa;
  final double cgpa;
  final String status; // active, inactive, graduated
  final DateTime registrationDate;

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNo,
    this.year = 1,
    this.semester = 1,
    this.branch = 'Computer Engineering',
    this.batch = 2024,
    this.gpa = 0.0,
    this.cgpa = 0.0,
    this.status = 'active',
    DateTime? registrationDate,
  }) : registrationDate = registrationDate ?? DateTime.now();

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      rollNo: (map['rollNo'] as String?) ?? '',
      year: (map['year'] as int?) ?? 1,
      semester: (map['semester'] as int?) ?? 1,
      branch: (map['branch'] as String?) ?? 'Computer Engineering',
      batch: (map['batch'] as int?) ?? 2024,
      gpa: (map['gpa'] as num?)?.toDouble() ?? 0.0,
      cgpa: (map['cgpa'] as num?)?.toDouble() ?? 0.0,
      status: (map['status'] as String?) ?? 'active',
      registrationDate: map['registrationDate'] is DateTime
          ? map['registrationDate']
          : DateTime.tryParse(map['registrationDate'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'rollNo': rollNo,
      'year': year,
      'semester': semester,
      'branch': branch,
      'batch': batch,
      'gpa': gpa,
      'cgpa': cgpa,
      'status': status,
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  StudentModel copyWith({
    String? id,
    String? name,
    String? email,
    String? rollNo,
    int? year,
    int? semester,
    String? branch,
    int? batch,
    double? gpa,
    double? cgpa,
    String? status,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      rollNo: rollNo ?? this.rollNo,
      year: year ?? this.year,
      semester: semester ?? this.semester,
      branch: branch ?? this.branch,
      batch: batch ?? this.batch,
      gpa: gpa ?? this.gpa,
      cgpa: cgpa ?? this.cgpa,
      status: status ?? this.status,
      registrationDate: registrationDate,
    );
  }
}
