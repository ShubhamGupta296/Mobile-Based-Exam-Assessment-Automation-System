import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/pdf_report_service.dart';

class DefaulterListDialog extends StatefulWidget {
  final String initialDepartment;
  final int initialSemester;
  final String initialDivision;

  const DefaulterListDialog({
    super.key,
    this.initialDepartment = 'Computer Engineering',
    this.initialSemester = 1,
    this.initialDivision = 'A',
  });

  static Future<void> show(
    BuildContext context, {
    String department = 'Computer Engineering',
    int semester = 1,
    String division = 'A',
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => DefaulterListDialog(
        initialDepartment: department,
        initialSemester: semester,
        initialDivision: division,
      ),
    );
  }

  @override
  State<DefaulterListDialog> createState() => _DefaulterListDialogState();
}

class _DefaulterListDialogState extends State<DefaulterListDialog> {
  final _firestore = FirestoreService();

  late String _selectedDepartment;
  late int _selectedSemester;
  late String _selectedDivision;

  bool _isLoading = true;
  List<Map<String, dynamic>> _defaulters = [];

  final List<String> _departments = [
    'Computer Engineering',
    'Information Technology',
    'Electronics',
  ];
  final List<String> _divisions = ['A', 'B', 'C'];
  final List<int> _semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  @override
  void initState() {
    super.initState();
    _selectedDepartment = widget.initialDepartment;
    _selectedSemester = widget.initialSemester;
    _selectedDivision = widget.initialDivision;
    _loadDefaulters();
  }

  Future<void> _loadDefaulters() async {
    setState(() => _isLoading = true);
    try {
      final list = await _firestore.getDefaulters(
        department: _selectedDepartment,
        semester: _selectedSemester,
        division: _selectedDivision,
        threshold: 75.0,
      );
      setState(() => _defaulters = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading defaulters: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_defaulters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No defaulters to export for this section.')),
      );
      return;
    }

    try {
      await PdfReportService.printDefaulterList(
        department: _selectedDepartment,
        semester: _selectedSemester,
        division: _selectedDivision,
        defaulters: _defaulters,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate Defaulter PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Attendance Defaulter Registry (< 75%)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter row
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: _selectedDepartment,
                    items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedDepartment = v);
                        _loadDefaulters();
                      }
                    },
                  ),
                  DropdownButton<int>(
                    value: _selectedSemester,
                    items: _semesters
                        .map((s) => DropdownMenuItem(value: s, child: Text('Semester $s')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedSemester = v);
                        _loadDefaulters();
                      }
                    },
                  ),
                  DropdownButton<String>(
                    value: _selectedDivision,
                    items: _divisions
                        .map((div) => DropdownMenuItem(value: div, child: Text('Div $div')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedDivision = v);
                        _loadDefaulters();
                      }
                    },
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                    onPressed: _defaulters.isEmpty ? null : _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF Notice'),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Summary banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _defaulters.isEmpty ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _defaulters.isEmpty ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Text(
                  _defaulters.isEmpty
                      ? 'No attendance defaulters found in this section! All students meet or exceed 75%.'
                      : 'Found ${_defaulters.length} student(s) below 75% attendance threshold in Section $_selectedDivision.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _defaulters.isEmpty ? Colors.green.shade800 : Colors.red.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Content List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _defaulters.isEmpty
                        ? const Center(
                            child: Text('No students currently below 75% in selected criteria.'),
                          )
                        : ListView.separated(
                            itemCount: _defaulters.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final item = _defaulters[i];
                              final percent = (item['percentage'] as num?)?.toDouble() ?? 0.0;
                              final attended = item['attended'] ?? 0;
                              final total = item['total'] ?? 0;
                              final shortage = item['shortage'] ?? 0;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.shade100,
                                  child: Text(
                                    '${percent.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${item['name']} (Roll: ${item['rollNo']})',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Attended: $attended / $total classes • Short by $shortage lectures for 75%',
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'DEFAULTER',
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
