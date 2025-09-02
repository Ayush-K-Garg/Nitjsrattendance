import 'package:flutter/material.dart';
import 'package:attend/models/scraped_data.dart'; // Using the new Course model

class AttendanceCard extends StatelessWidget {
  final Course course; // Changed from AttendanceRecord to Course
  const AttendanceCard({super.key, required this.course});

  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) return const Color(0xFF2ECC71); // Green
    if (percentage >= 60) return const Color(0xFFF39C12); // Orange
    return const Color(0xFFE74C3C); // Red
  }

  @override
  Widget build(BuildContext context) {
    // The percentage is now calculated via the getter in the Course model
    final percentageColor = _getPercentageColor(course.percentage);
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
                  Text(course.subjectName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),

                  // --- THIS IS THE FIX ---
                  // Added a row to display the faculty name with an icon
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          course.facultyName,
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // --- END OF FIX ---

                  const SizedBox(height: 12),
                  Text('Attended: ${course.classesAttended} of ${course.totalClasses}', style: TextStyle(color: Colors.grey[300], fontSize: 14)),
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
                    value: course.percentage / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(percentageColor),
                  ),
                  Center(
                    child: Text('${course.percentage.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: percentageColor)),
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

