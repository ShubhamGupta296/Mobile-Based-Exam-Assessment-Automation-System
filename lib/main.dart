import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

  try {
    await FirestoreService().restoreDefaultCollectionStructure();
  } catch (_) {
    // Ignore startup seeding failures here so the app can still open.
  }

  runApp(const ExamAssessmentApp());
}
