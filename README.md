# Exam Assessment Automation System

A Flutter-based academic ERP application for managing exam assessments, student performance, attendance, and result publishing. Built with **Firebase Authentication** and **Cloud Firestore**.

![Flutter](https://img.shields.io/badge/Flutter-3.41-blue)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-orange)
![Dart](https://img.shields.io/badge/Dart-3.11-blue)

---

## Features

### Authentication
- Email/password signup and login
- Role-based access: **Admin**, **Teacher**, **Student**
- Admin approval for new registrations

### Admin Panel
- View and manage students, teachers, subjects, and departments
- Search and filter users
- Assign Computer Engineering subjects by year and semester
- Approve or reject user registrations
- Publish results (lock marks editing)
- Analytics dashboard with charts and PDF reports

### Teacher Module
- View student list
- Enter internal and external marks
- Record attendance
- Auto-calculate total, grade, and grade point
- Result lock enforcement after admin publishes

### Student Module
- View profile and subject-wise marks
- View GPA, CGPA, and attendance summary
- Pull-to-refresh dashboard

### Subject Assignment
- Auto-assign CE curriculum subjects (DSA, OOPS, DBMS, CN, OS, TOC, COA, etc.)
- Subject codes (e.g., DSA101, DBMS201, OS301)
- Teacher-specific subject assignment

### Analytics & Reports
- GPA / CGPA / attendance trend graphs
- Subject, semester, and year performance comparison
- Report card and academic transcript generation
- Downloadable PDF reports

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Material 3) |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Charts | fl_chart |
| PDF Reports | pdf, printing |

---

## Project Structure

```
lib/
├── admin/          # Admin dashboard & analytics
├── auth/           # Login & signup screens
├── models/         # Firestore data models
├── services/       # Auth, Firestore, ERP, Analytics services
├── student/        # Student dashboard
├── teacher/        # Teacher dashboard
├── screens/        # App entry screens
└── widgets/        # Shared UI components
```

---

## Prerequisites

Before running the project, install:

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.41+)
2. [Firebase CLI](https://firebase.google.com/docs/cli) (for deployment)
3. A Firebase project with:
   - **Authentication** → Email/Password enabled
   - **Cloud Firestore** database created

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/exam-assessment-automation-system.git
cd exam-assessment-automation-system
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

This project uses `lib/firebase_options.dart` for web configuration.

To regenerate for your own Firebase project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Deploy Firestore indexes

```bash
firebase deploy --only firestore:indexes
```

### 5. Run locally (Web)

```bash
flutter run -d chrome
```

### 6. Run on Android

```bash
flutter run -d android
```

> **Note:** For Android/iOS builds, add platform-specific Firebase config via `flutterfire configure`.

---

## Firestore Collections

| Collection | Description |
|------------|-------------|
| `users` | User profiles (uid, name, email, role, approvalStatus) |
| `students` | Student records (rollNo, year, semester, branch) |
| `subjects` | Subject catalog (code, year, semester, teacherId) |
| `marks` | Internal, external, total, grade, remark |
| `attendance` | Present/total classes, percentage |
| `departments` | Department management |
| `notifications` | System notifications |
| `config/result` | Result lock status (`resultLocked`) |

---

## User Roles

| Role | Access |
|------|--------|
| **Admin** | Full management, analytics, publish results |
| **Teacher** | Enter marks & attendance for assigned subjects |
| **Student** | View own marks, GPA, CGPA, attendance |

---

## Deployment

### Option A: Deploy Web App to Firebase Hosting (Recommended)

Firebase Hosting works best with this project since it already uses Firebase Auth and Firestore.

#### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

#### Step 2: Initialize Firebase in project folder

```bash
firebase init
```

Select:
- **Hosting**
- Use existing project: `android-app-d1e79` (or your project)
- Public directory: `build/web`
- Single-page app: **Yes**
- Overwrite `index.html`: **No**

#### Step 3: Build Flutter web app

```bash
flutter build web --release
```

#### Step 4: Deploy to Firebase Hosting

```bash
firebase deploy --only hosting
```

Your app will be live at:
`https://YOUR_PROJECT_ID.web.app`

---

### Option B: Deploy Android APK

```bash
flutter build apk --release
```

APK output:
`build/app/outputs/flutter-apk/app-release.apk`

Share or upload to Google Play Console.

---

### Option C: Deploy using GitHub Actions (CI/CD)

Add `.github/workflows/deploy.yml` to auto-deploy on push to `main`:

```yaml
name: Deploy to Firebase Hosting
on:
  push:
    branches: [main]

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.4'
      - run: flutter pub get
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: android-app-d1e79
```

---

## Upload to GitHub

```bash
git init
git add .
git commit -m "Initial commit: Exam Assessment Automation System"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/exam-assessment-automation-system.git
git push -u origin main
```

> Add a `.gitignore` — Flutter projects already include one. Do **not** commit sensitive server-side keys.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `MyApp` not found | Use `ExamAssessmentApp` in `main.dart` |
| Firebase init error | Run `flutterfire configure` |
| Firestore permission denied | Update Firestore security rules in Firebase Console |
| Symlink error on Windows | Enable **Developer Mode** in Windows Settings |
| Missing Visual Studio (Windows desktop) | Install VS Build Tools or use `flutter run -d chrome` |

---

## Firestore Security Rules (Development)

For testing, use these rules in Firebase Console → Firestore → Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

> Tighten rules before production deployment.

---

## License

This project is for academic/educational use.

---

## Author

Developed as part of the **Exam Assessment Automation System** academic project.
