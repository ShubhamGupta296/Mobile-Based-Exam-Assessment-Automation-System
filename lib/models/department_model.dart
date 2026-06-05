/// Department document in `departments` collection.
///
/// Fields:
/// - id
/// - name
/// - code
/// - headId (Teacher UID)
/// - totalStudents
/// - createdDate
class DepartmentModel {
  final String id;
  final String name;
  final String code;
  final String headId;
  final int totalStudents;
  final DateTime createdDate;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.headId,
    this.totalStudents = 0,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      code: (map['code'] as String?) ?? '',
      headId: (map['headId'] as String?) ?? '',
      totalStudents: (map['totalStudents'] as int?) ?? 0,
      createdDate: map['createdDate'] is DateTime
          ? map['createdDate'] as DateTime
          : DateTime.tryParse(map['createdDate'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'code': code,
      'headId': headId,
      'totalStudents': totalStudents,
      'createdDate': createdDate.toIso8601String(),
    };
  }
}
