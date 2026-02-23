import 'package:flutter/material.dart';

class RiskCard extends StatelessWidget {
  final String diseaseName;
  final String riskLevel;
  final String description;

  const RiskCard({
    super.key,
    required this.diseaseName,
    required this.riskLevel,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    Color riskColor;
    IconData riskIcon;

    switch (riskLevel.toLowerCase()) {
      case 'high':
      case 'critical':
        riskColor = Colors.red;
        riskIcon = Icons.error_outline;
        break;
      case 'moderate':
        riskColor = Colors.orange;
        riskIcon = Icons.warning_amber;
        break;
      case 'low':
      default:
        riskColor = Colors.green;
        riskIcon = Icons.check_circle_outline;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(riskIcon, color: riskColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    diseaseName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    riskLevel.toUpperCase(),
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
