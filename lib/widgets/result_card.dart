import 'package:flutter/material.dart';
import 'package:attend/models/result_record.dart';

class ResultCard extends StatelessWidget {
  final ResultRecord record;
  const ResultCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
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
                  Text(record.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(record.subjectCode, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record.grade,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor),
                  ),
                ),
                if (record.sgpa.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text("SGPA: ${record.sgpa}", style: TextStyle(color: Colors.grey[300], fontSize: 12))
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}

