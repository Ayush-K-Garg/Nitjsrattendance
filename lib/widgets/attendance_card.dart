import 'package:flutter/material.dart';
import 'package:attend/models/attendance_record.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  const AttendanceCard({super.key, required this.record});

  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) return const Color(0xFF2ECC71); // Green
    if (percentage >= 60) return const Color(0xFFF39C12); // Orange
    return const Color(0xFFE74C3C); // Red
  }

  @override
  Widget build(BuildContext context) {
    final percentageColor = _getPercentageColor(record.percentage);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.subjectName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(record.subjectCode, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  const SizedBox(height: 12),
                  Text('Attended: ${record.classesAttended} of ${record.totalClasses}', style: TextStyle(color: Colors.grey[300], fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: record.percentage / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(percentageColor),
                  ),
                  Center(
                    child: Text('${record.percentage.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: percentageColor)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

