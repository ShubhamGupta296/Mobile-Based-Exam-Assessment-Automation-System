# College ERP System with Student Performance Management

A Flutter and Firebase-based College ERP System designed to simplify academic administration and student performance tracking. The platform provides dedicated dashboards for Students, Teachers, and Administrators with secure authentication and real-time data management.

## Features

### Student Module

* Student Registration & Login
* Profile Management
* Subject-wise Marks
* Attendance Tracking
* GPA & CGPA Calculation
* Academic Progress Monitoring
* Performance Dashboard

### Teacher Module

* Teacher Registration & Login
* View Assigned Students
* Add and Update Marks
* Lock/Unlock Marks
* Manage Attendance
* Track Student Performance

### Admin Module

* Manage Students and Teachers
* Manage Subjects and Departments
* User Role Management
* Academic Monitoring
* System Administration

### Academic Management

* Subject Assignment
* Internal & External Marks
* Attendance Management
* Semester-wise Records
* Year-wise Records
* Result Processing

### Analytics & Reports

* GPA and CGPA Analysis
* Attendance Analytics
* Subject-wise Performance
* Academic Progress Reports
* Interactive Dashboards

## Tech Stack

* Flutter
* Firebase Authentication
* Cloud Firestore
* Dart
* Material UI

## Project Structure

```bash
lib/
├── admin/
├── auth/
├── models/
├── services/
├── student/
├── teacher/
├── widgets/
└── main.dart
```

## Installation

### Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME.git
cd YOUR_REPOSITORY_NAME
```

### Install Dependencies

```bash
flutter pub get
```

### Configure Firebase

1. Create a Firebase Project.
2. Enable Authentication.
3. Enable Cloud Firestore.
4. Download Firebase configuration files.
5. Run:

```bash
flutterfire configure
```

### Run Application

```bash
flutter run
```

For Web:

```bash
flutter run -d chrome
```

## Firebase Collections

```text
users
students
teachers
subjects
marks
attendance
notifications
departments
```

## User Roles

### Student

* View marks
* View attendance
* Track GPA/CGPA
* View academic progress

### Teacher

* Manage marks
* Manage attendance
* Monitor student performance

### Admin

* Manage users
* Manage subjects
* Manage departments
* Monitor system activity

## Future Enhancements

* AI-based Performance Analysis
* PDF Report Generation
* Email Notifications
* Mobile Push Notifications
* Advanced Analytics Dashboard
* Placement Management Module

## Demo Credentials
### Student Accounts

| Email              | Password           |
| ------------------ | ------------------ |
| `abcd@gmail.com`   | `abcd@gmail.com`   |
| `shub@gmail.com`   | `shub@gmail.com`   |
| `shubhu@gmail.com` | `shubhu@gmail.com` |

### Teacher Account

| Email               | Password            |
| ------------------- | ------------------- |
| `ankit12@gmail.com` | `ankit12@gmail.com` |

### Admin Account

| Email                  | Password               |
| ---------------------- | ---------------------- |
| `admin12345@gmail.com` | `admin12345@gmail.com` |

> These accounts are provided for testing and demonstration purposes only.

## Author

Shubham Gupta

## License

This project is developed for educational and academic purposes.
