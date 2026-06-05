import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/student_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserModel?> fetchCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final snap = await _db.collection('users').doc(user.uid).get();
    final data = snap.data();
    if (data == null) return null;

    return UserModel.fromMap(data);
  }

  Future<UserModel> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required String role, // admin | teacher | student
    int year = 1,
    int semester = 1,
    int batch = 2024,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final user = UserModel(uid: uid, name: name, email: email, role: role);

    await _db.collection('users').doc(uid).set(user.toMap());

    // If student role, also create student record
    if (role == 'student') {
      final student = StudentModel(
        id: uid,
        name: name,
        email: email,
        rollNo: 'AUTO_${uid.substring(0, 8)}',
        year: year,
        semester: semester,
        batch: batch,
      );
      await _db.collection('students').doc(uid).set(student.toMap());
    }

    return user;
  }

  Future<UserCredential> loginWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() => _auth.signOut();
}
