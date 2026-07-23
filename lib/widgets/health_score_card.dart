import 'package:flutter/material.dart';

import '../services/health_score_service.dart';

/// Dashboard card showing today's health-engagement score as a ring, with a
/// tap to reveal the full breakdown.
class HealthScoreCard extends StatefulWidget {
  const HealthScoreCard({super.key});

  @override
  State<HealthScoreCard> createState() => _HealthScoreCardState();
}

class _HealthScoreCardState extends State<HealthScoreCard> {
  HealthScore? _score;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await HealthScoreService.compute();
    if (mounted) setState(() => _score = s);
  }

  Color _colorFor(int total) {
    if (total >= 70) return Colors.green;
    if (total >= 50) return Colors.lightGreen;
    if (total >= 30) return Colors.orange;
    return Colors.redAccent;
  }

  void _showBreakdown() {
    final score = _score;
    if (score == null) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Health Score: ${score.total}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('(${score.grade})',
                    style: TextStyle(color: _colorFor(score.total))),
              ],
            ),
            const SizedBox(height: 4),
            Text('Based on how you tracked your health today.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ...score.parts.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                          p.complete
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: p.complete ? Colors.green : Colors.grey,
                          size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            if (!p.complete)
                              Text(p.hint,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Text('${p.earned}/${p.max}',
                          style: TextStyle(
                              color: p.complete ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final total = score?.total ?? 0;
    final color = _colorFor(total);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: score == null ? null : _showBreakdown,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: score == null ? null : total / 100,
                        strokeWidth: 6,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    if (score != null)
                      Text('$total',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: color)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Health Score',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 6),
                        if (score != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(score.grade,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      score == null
                          ? 'Calculating...'
                          : score.topSuggestion,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
