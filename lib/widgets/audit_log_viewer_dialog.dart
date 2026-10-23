import 'package:flutter/material.dart';
import '../models/audit_log_model.dart';
import '../services/firestore_service.dart';

class AuditLogViewerDialog extends StatefulWidget {
  const AuditLogViewerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const AuditLogViewerDialog(),
    );
  }

  @override
  State<AuditLogViewerDialog> createState() => _AuditLogViewerDialogState();
}

class _AuditLogViewerDialogState extends State<AuditLogViewerDialog> {
  final _firestore = FirestoreService();
  bool _isLoading = true;
  List<AuditLogModel> _logs = [];
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _firestore.getAuditLogs(limit: 100);
      setState(() => _logs = logs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load audit logs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter.isEmpty
        ? _logs
        : _logs.where((l) {
            final q = _filter.toLowerCase();
            return l.performedBy.toLowerCase().contains(q) ||
                l.action.toLowerCase().contains(q) ||
                l.studentRollNo.toLowerCase().contains(q) ||
                l.subjectId.toLowerCase().contains(q);
          }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
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
                      const Icon(Icons.history_edu, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Academic Audit Trail',
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
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by user, action, roll no, or subject...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(child: Text('No audit log entries found.'))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final item = filtered[i];
                              final timeStr =
                                  '${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year} ${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';

                              final hasDiff = item.details.containsKey('previousTotal');
                              return ListTile(
                                isThreeLine: true,
                                leading: CircleAvatar(
                                  backgroundColor: item.action.contains('LOCK')
                                      ? Colors.orange.shade100
                                      : Colors.indigo.shade100,
                                  child: Icon(
                                    item.action.contains('LOCK') ? Icons.lock : Icons.edit_note,
                                    color: item.action.contains('LOCK') ? Colors.orange.shade800 : Colors.indigo.shade800,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  '${item.action} • ${item.subjectId.isNotEmpty ? item.subjectId : "System"}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'By: ${item.performedBy} (${item.role}) • Roll: ${item.studentRollNo.isNotEmpty ? item.studentRollNo : "N/A"}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (hasDiff)
                                      Text(
                                        'Score changed: ${item.details['previousTotal']}/100 → ${item.details['newTotal']}/100 (Int: ${item.details['previousInternal']}→${item.details['newInternal']}, Ext: ${item.details['previousExternal']}→${item.details['newExternal']})',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueGrey.shade800,
                                        ),
                                      ),
                                    Text(
                                      timeStr,
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loadLogs,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
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
