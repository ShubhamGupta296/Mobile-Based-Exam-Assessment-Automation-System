import 'package:flutter/material.dart';

/// Reusable badge displaying attendance health status:
/// - Good (Green) >= 75%
/// - Warning (Orange/Yellow) 60% - 74%
/// - Critical / Shortage (Red) < 60%
class AttendanceHealthBadge extends StatelessWidget {
  final double percentage;
  final bool showLabel;

  const AttendanceHealthBadge({
    super.key,
    required this.percentage,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    if (percentage >= 75.0) {
      color = Colors.green.shade700;
      label = 'Good (${percentage.toStringAsFixed(1)}%)';
      icon = Icons.check_circle_outline;
    } else if (percentage >= 60.0) {
      color = Colors.orange.shade800;
      label = 'Warning (${percentage.toStringAsFixed(1)}%)';
      icon = Icons.warning_amber_rounded;
    } else {
      color = Colors.red.shade700;
      label = 'Shortage (${percentage.toStringAsFixed(1)}%)';
      icon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
