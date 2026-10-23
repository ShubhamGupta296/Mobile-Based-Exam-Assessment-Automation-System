import 'package:flutter/material.dart';
import '../models/daily_attendance_model.dart';

/// UI component displaying the last 5 lectures recorded for a subject.
class LectureHistoryWidget extends StatelessWidget {
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final List<DailyAttendanceModel> lectures;
  final VoidCallback? onRefresh;

  const LectureHistoryWidget({
    super.key,
    required this.lectures,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (lectures.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last 5 Lecture History',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (onRefresh != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: onRefresh,
                      tooltip: 'Refresh History',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'No recent lecture records found for this selection.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 20, color: Colors.indigo),
                    const SizedBox(width: 6),
                    Text(
                      'Last ${lectures.length} Lecture History',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: onRefresh,
                    tooltip: 'Refresh History',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: lectures.map((lecture) {
                  final monthStr = _monthNames[(lecture.date.month - 1).clamp(0, 11)];
                  final dateStr = '$monthStr ${lecture.date.day.toString().padLeft(2, '0')}';
                  final pct = lecture.attendancePercentage;

                  final badgeColor = pct >= 75
                      ? Colors.green.shade700
                      : (pct >= 60 ? Colors.orange.shade800 : Colors.red.shade700);

                  return Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'L${lecture.lectureNumber} • $dateStr',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Present: ${lecture.presentStudentIds.length}/${lecture.totalStudents}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${pct.toStringAsFixed(0)}% Turnout',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
