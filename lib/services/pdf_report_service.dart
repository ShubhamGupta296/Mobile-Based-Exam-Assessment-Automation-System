import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/attendance_model.dart';
import '../models/marks_model.dart';
import '../models/student_model.dart';

class PdfReportService {
  /// Generates and previews/prints an official Student Transcript / Grade Card.
  static Future<void> printStudentGradeCard({
    required StudentModel student,
    required List<MarksModel> marks,
    required List<AttendanceModel> attendance,
    required double semesterGpa,
    required double cgpa,
    required double attendanceAverage,
  }) async {
    final pdfBytes = await generateStudentGradeCardBytes(
      student: student,
      marks: marks,
      attendance: attendance,
      semesterGpa: semesterGpa,
      cgpa: cgpa,
      attendanceAverage: attendanceAverage,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'GradeCard_${student.rollNo}_Sem${student.semester}.pdf',
    );
  }

  /// Generates the raw PDF bytes for a Student Grade Card.
  static Future<Uint8List> generateStudentGradeCardBytes({
    required StudentModel student,
    required List<MarksModel> marks,
    required List<AttendanceModel> attendance,
    required double semesterGpa,
    required double cgpa,
    required double attendanceAverage,
  }) async {
    final doc = pw.Document();

    final now = DateTime.now();
    final formattedDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    // Map attendance by subject
    final attMap = {for (var a in attendance) a.subjectId: a};

    // Calculate total marks scored & maximum
    final totalScored = marks.fold<int>(0, (sum, m) => sum + m.total);
    final maxPossible = marks.isNotEmpty ? marks.length * 100 : 100;
    final overallPercent = marks.isNotEmpty ? (totalScored / maxPossible) * 100 : 0.0;

    String resultClassification;
    if (marks.isEmpty) {
      resultClassification = 'AWAITING RESULTS';
    } else if (marks.any((m) => m.grade == 'F')) {
      resultClassification = 'FAIL / BACKLOG';
    } else if (overallPercent >= 75.0) {
      resultClassification = 'FIRST CLASS WITH DISTINCTION';
    } else if (overallPercent >= 60.0) {
      resultClassification = 'FIRST CLASS';
    } else if (overallPercent >= 50.0) {
      resultClassification = 'SECOND CLASS';
    } else {
      resultClassification = 'PASS CLASS';
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // INSTITUTION HEADER
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.indigo900, width: 2),
                  ),
                ),
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'COLLEGE OF ENGINEERING & TECHNOLOGY',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Department of ${student.branch}',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'OFFICIAL SEMESTER GRADE CARD & TRANSCRIPT',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date of Issue: $formattedDate',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey200,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'CONFIDENTIAL & VERIFIED',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // STUDENT DETAILS BOX
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildDetailText('Student Name:', student.name),
                        pw.SizedBox(height: 4),
                        _buildDetailText('Roll Number:', student.rollNo),
                        pw.SizedBox(height: 4),
                        _buildDetailText('Email Address:', student.email),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildDetailText('Academic Year:', 'Year ${student.year} (Batch ${student.batch})'),
                        pw.SizedBox(height: 4),
                        _buildDetailText('Semester & Div:', 'Semester ${student.semester} - Section ${student.division}'),
                        pw.SizedBox(height: 4),
                        _buildDetailText('Department:', student.branch),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // MARKS & ATTENDANCE TABLE
              pw.Text(
                'Course Performance Breakdown',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.0), // Subject
                  1: pw.FlexColumnWidth(1.2), // ISE (Internal)
                  2: pw.FlexColumnWidth(1.2), // ESE (External)
                  3: pw.FlexColumnWidth(1.2), // Total
                  4: pw.FlexColumnWidth(1.0), // Grade
                  5: pw.FlexColumnWidth(1.0), // GP
                  6: pw.FlexColumnWidth(1.6), // Attendance
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                    children: [
                      _buildTableCell('Subject / Course', isHeader: true),
                      _buildTableCell('ISE (/40)', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('ESE (/60)', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Total (/100)', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Grade', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('GP', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Attendance', isHeader: true, align: pw.TextAlign.center),
                    ],
                  ),
                  // Subject Rows
                  ...marks.map((m) {
                    final att = attMap[m.subjectId];
                    final attStr = att != null
                        ? '${att.presentClasses}/${att.totalClasses} (${att.percentage.toStringAsFixed(0)}%)'
                        : '-';
                    return pw.TableRow(
                      children: [
                        _buildTableCell(m.subjectId),
                        _buildTableCell('${m.internal}', align: pw.TextAlign.center),
                        _buildTableCell('${m.external}', align: pw.TextAlign.center),
                        _buildTableCell('${m.total}', align: pw.TextAlign.center, isBold: true),
                        _buildTableCell(m.grade, align: pw.TextAlign.center, isBold: true),
                        _buildTableCell(m.gradePoint.toStringAsFixed(1), align: pw.TextAlign.center),
                        _buildTableCell(attStr, align: pw.TextAlign.center),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 14),

              // PERFORMANCE SUMMARY CARDS
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatBox('SEMESTER GPA', semesterGpa.toStringAsFixed(2), '/ 10.0', PdfColors.indigo700),
                  _buildStatBox('CUMULATIVE CGPA', cgpa.toStringAsFixed(2), '/ 10.0', PdfColors.indigo900),
                  _buildStatBox('TOTAL MARKS', '$totalScored / $maxPossible', '(${overallPercent.toStringAsFixed(1)}%)', PdfColors.teal700),
                  _buildStatBox('ATTENDANCE AVG', '${attendanceAverage.toStringAsFixed(1)}%', attendanceAverage >= 75 ? 'ELIGIBLE' : 'DEFAULTER', attendanceAverage >= 75 ? PdfColors.green700 : PdfColors.red700),
                ],
              ),
              pw.SizedBox(height: 12),

              // RESULT BANNER
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: pw.BoxDecoration(
                  color: resultClassification.contains('FAIL') ? PdfColors.red50 : PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(
                    color: resultClassification.contains('FAIL') ? PdfColors.red300 : PdfColors.indigo300,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ACADEMIC RESULT CLASSIFICATION:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Text(
                      resultClassification,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: resultClassification.contains('FAIL') ? PdfColors.red800 : PdfColors.indigo900,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // SIGNATURE & FOOTER SECTION
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
                ),
                padding: const pw.EdgeInsets.only(top: 24),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSignatureLine('Student Signature'),
                    _buildSignatureLine('Class Coordinator'),
                    _buildSignatureLine('Head of Department (CE)'),
                    _buildSignatureLine('Controller of Examinations'),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Note: This document is an automated electronic transcript generated by the Exam Assessment Automation System.',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Generates and previews/prints an official Defaulter List (< 75% attendance).
  static Future<void> printDefaulterList({
    required String department,
    required int semester,
    required String division,
    required List<Map<String, dynamic>> defaulters,
  }) async {
    final pdfBytes = await generateDefaulterListBytes(
      department: department,
      semester: semester,
      division: division,
      defaulters: defaulters,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Defaulter_List_${department.replaceAll(' ', '_')}_Sem${semester}_Div$division.pdf',
    );
  }

  /// Generates raw bytes for Defaulter List.
  static Future<Uint8List> generateDefaulterListBytes({
    required String department,
    required int semester,
    required String division,
    required List<Map<String, dynamic>> defaulters,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.red800, width: 2),
                  ),
                ),
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ACADEMIC ATTENDANCE DEFAULTER NOTICE',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Department of $department • Semester $semester • Section $division',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Text(
                      'Date: $dateStr',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // WARNING TEXT
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.red200),
                ),
                child: pw.Text(
                  'CRITICAL: The students listed below have secured less than 75% overall attendance and are classified as DEFAULTERS under institute academic guidelines. They may be disqualified from the upcoming End-Semester Examination unless condoned by the Dean/HoD.',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.red900,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // TABLE
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.2), // Roll No
                  1: pw.FlexColumnWidth(3.0), // Name
                  2: pw.FlexColumnWidth(1.5), // Attended / Total
                  3: pw.FlexColumnWidth(1.5), // Percentage
                  4: pw.FlexColumnWidth(1.8), // Shortage Lectures
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Roll No', isHeader: true),
                      _buildTableCell('Student Name', isHeader: true),
                      _buildTableCell('Attended / Total', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Attendance %', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Shortage Status', isHeader: true, align: pw.TextAlign.center),
                    ],
                  ),
                  ...defaulters.map((item) {
                    final percent = (item['percentage'] as num?)?.toDouble() ?? 0.0;
                    final attended = item['attended'] ?? 0;
                    final total = item['total'] ?? 0;
                    final shortage = item['shortage'] ?? 0;

                    return pw.TableRow(
                      children: [
                        _buildTableCell(item['rollNo']?.toString() ?? '-'),
                        _buildTableCell(item['name']?.toString() ?? '-'),
                        _buildTableCell('$attended / $total', align: pw.TextAlign.center),
                        _buildTableCell(
                          '${percent.toStringAsFixed(1)}%',
                          align: pw.TextAlign.center,
                          isBold: true,
                        ),
                        _buildTableCell(
                          '$shortage classes short',
                          align: pw.TextAlign.center,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.Spacer(),

              // SIGNATURES
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSignatureLine('Attendance In-Charge'),
                  _buildSignatureLine('Class Coordinator'),
                  _buildSignatureLine('Head of Department'),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // Helper widgets
  static pw.Widget _buildDetailText(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.indigo900 : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildStatBox(String title, String val, String sub, PdfColor color) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: color),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            val,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color),
          ),
          pw.Text(
            sub,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureLine(String designation) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 110,
          height: 1,
          color: PdfColors.grey500,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          designation,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
        ),
      ],
    );
  }
}
