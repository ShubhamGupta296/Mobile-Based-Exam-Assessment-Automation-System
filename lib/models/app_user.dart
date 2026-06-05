/// User document in `users` collection.
///
/// Fields:
/// - uid
/// - name
/// - email
/// - role (admin | teacher | student)
/// - approvalStatus (pending | approved | rejected)
/// - departmentId (optional)
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String approvalStatus;
  final String departmentId;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.approvalStatus = 'approved',
    this.departmentId = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: (map['uid'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: (map['role'] as String?) ?? '',
      approvalStatus: (map['approvalStatus'] as String?) ?? 'approved',
      departmentId: (map['departmentId'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'approvalStatus': approvalStatus,
      'departmentId': departmentId,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? approvalStatus,
    String? departmentId,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      departmentId: departmentId ?? this.departmentId,
    );
  }
}

