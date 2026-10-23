import 'package:flutter/material.dart';
import '../models/marks_model.dart';
import '../models/student_model.dart';
import '../services/firestore_service.dart';

enum BulkImportType { students, marks }

class BulkCsvImportDialog extends StatefulWidget {
  final BulkImportType type;
  final String? subjectId;
  final int? semester;
  final String? teacherUidOrEmail;

  const BulkCsvImportDialog({
    super.key,
    required this.type,
    this.subjectId,
    this.semester,
    this.teacherUidOrEmail,
  });

  static Future<void> showStudentsImport(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const BulkCsvImportDialog(type: BulkImportType.students),
    );
  }

  static Future<void> showMarksImport(
    BuildContext context, {
    required String subjectId,
    required int semester,
    required String teacherUidOrEmail,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => BulkCsvImportDialog(
        type: BulkImportType.marks,
        subjectId: subjectId,
        semester: semester,
        teacherUidOrEmail: teacherUidOrEmail,
      ),
    );
  }

  @override
  State<BulkCsvImportDialog> createState() => _BulkCsvImportDialogState();
}

class _BulkCsvImportDialogState extends State<BulkCsvImportDialog> {
  final _firestore = FirestoreService();
  final _textController = TextEditingController();

  bool _isImporting = false;
  String? _statusMessage;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    _fillSampleTemplate();
  }

  void _fillSampleTemplate() {
    if (widget.type == BulkImportType.students) {
      _textController.text =
          'rollNo,name,email,branch,year,semester,division,batch\n'
          'CE101,Aarav Patel,aarav@gmail.com,Computer Engineering,1,1,A,2024\n'
          'CE102,Diya Sharma,diya@gmail.com,Computer Engineering,1,1,A,2024\n'
          'CE103,Rohan Verma,rohan@gmail.com,Computer Engineering,1,1,B,2024';
    } else {
      _textController.text =
          'rollNo,internal,external,remark\n'
          'CE101,28,62,Excellent\n'
          'CE102,24,55,Good progress\n'
          'CE103,15,35,Needs improvement';
    }
  }

  Future<void> _processImport() async {
    final rawText = _textController.text.trim();
    if (rawText.isEmpty) {
      setState(() => _statusMessage = 'Please enter or paste CSV data.');
      return;
    }

    setState(() {
      _isImporting = true;
      _statusMessage = null;
      _errors = [];
    });

    try {
      final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.length <= 1) {
        throw Exception('CSV must contain a header row followed by at least one data row.');
      }

      final dataLines = lines.sublist(1);
      int importedCount = 0;

      if (widget.type == BulkImportType.students) {
        for (int i = 0; i < dataLines.length; i++) {
          final row = dataLines[i].split(',').map((c) => c.trim()).toList();
          if (row.length < 3) {
            _errors.add('Row ${i + 2}: Insufficient columns (must have at least rollNo, name, email)');
            continue;
          }

          final rollNo = row[0];
          final name = row[1];
          final email = row[2];
          final branch = row.length > 3 && row[3].isNotEmpty ? row[3] : 'Computer Engineering';
          final year = row.length > 4 ? int.tryParse(row[4]) ?? 1 : 1;
          final semester = row.length > 5 ? int.tryParse(row[5]) ?? 1 : 1;
          final division = row.length > 6 && row[6].isNotEmpty ? row[6] : 'A';
          final batch = row.length > 7 ? int.tryParse(row[7]) ?? 2024 : 2024;

          final studentId = 'std_${rollNo.toLowerCase()}';
          final student = StudentModel(
            id: studentId,
            rollNo: rollNo,
            name: name,
            email: email,
            branch: branch,
            year: year,
            semester: semester,
            division: division,
            batch: batch,
          );

          await _firestore.addStudent(student);
          importedCount++;
        }
      } else {
        // Marks bulk entry
        final allStudents = await _firestore.getAllStudents();
        final studentMap = {for (var s in allStudents) s.rollNo.toLowerCase(): s};

        final subject = widget.subjectId ?? 'DSA';
        final sem = widget.semester ?? 1;
        final teacher = widget.teacherUidOrEmail ?? 'teacher@system';

        for (int i = 0; i < dataLines.length; i++) {
          final row = dataLines[i].split(',').map((c) => c.trim()).toList();
          if (row.length < 3) {
            _errors.add('Row ${i + 2}: Must have rollNo, internal, external marks');
            continue;
          }

          final rollNo = row[0];
          final internal = int.tryParse(row[1]) ?? 0;
          final external = int.tryParse(row[2]) ?? 0;
          final remark = row.length > 3 ? row[3] : '';

          final student = studentMap[rollNo.toLowerCase()];
          if (student == null) {
            _errors.add('Row ${i + 2}: Student with rollNo "$rollNo" not found.');
            continue;
          }

          final total = internal + external;
          final pct = MarksModel.calculatePercentage(internal, external);
          final gp = MarksModel.calculateGradePoint(total);
          final grade = MarksModel.getGrade(total);

          final marksModel = MarksModel(
            studentId: student.id,
            subjectId: subject,
            semester: sem,
            internal: internal,
            external: external,
            total: total,
            percentage: pct,
            gradePoint: gp,
            grade: grade,
            remark: remark,
          );

          await _firestore.updateMarksWithAudit(
            studentId: student.id,
            subjectId: subject,
            updatedMarks: marksModel,
            performedBy: teacher,
            role: 'teacher',
            studentRollNo: rollNo,
          );

          importedCount++;
        }
      }

      setState(() {
        _statusMessage = 'Successfully processed $importedCount record(s)!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Import error: $e';
      });
    } finally {
      setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == BulkImportType.students
        ? 'Bulk Import Students (CSV)'
        : 'Bulk Import Marks for ${widget.subjectId ?? "Subject"} (CSV)';

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_view, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Paste your CSV data below or edit the sample. The first line must be the column header.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'rollNo,name,email...',
                  ),
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _statusMessage!.contains('error') || _statusMessage!.contains('Please')
                        ? Colors.red
                        : Colors.green.shade800,
                  ),
                ),
              ],
              if (_errors.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 80),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _errors.length,
                    itemBuilder: (_, i) => Text(
                      '• ${_errors[i]}',
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _fillSampleTemplate,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset Template'),
                  ),
                  FilledButton.icon(
                    onPressed: _isImporting ? null : _processImport,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.file_upload),
                    label: Text(_isImporting ? 'Importing...' : 'Start Import'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
