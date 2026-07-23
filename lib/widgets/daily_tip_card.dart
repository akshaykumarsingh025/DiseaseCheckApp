import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../services/daily_tip_service.dart';
import '../utils/doctor_info.dart';

/// A daily women's-health "Tip of the Day" card for the home screen — a small
/// reason to open the app every morning. Shows a fresh tip each day, with a
/// shuffle button (see another) and a share button.
class DailyTipCard extends StatefulWidget {
  const DailyTipCard({super.key});

  @override
  State<DailyTipCard> createState() => _DailyTipCardState();
}

class _DailyTipCardState extends State<DailyTipCard> {
  late HealthTip _tip;
  bool _isToday = true;

  @override
  void initState() {
    super.initState();
    _tip = DailyTipService.todayTip();
  }

  void _shuffle() {
    final next = DailyTipService.tipAt(Random().nextInt(DailyTipService.tips.length));
    setState(() {
      _tip = next;
      _isToday = false;
    });
  }

  void _share() {
    Share.share(
      'Health Tip (${_tip.category}):\n\n${_tip.text}\n\n'
      '— shared from ${DoctorInfo.name}\'s DiseaseCheck app',
    );
  }

  IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'nutrition':
        return Icons.restaurant;
      case 'cycle':
        return Icons.calendar_month;
      case 'pcos':
        return Icons.female;
      case 'pregnancy':
      case 'fertility':
        return Icons.pregnant_woman;
      case 'screening':
      case 'awareness':
        return Icons.health_and_safety;
      case 'bone health':
        return Icons.accessibility_new;
      case 'menopause':
        return Icons.spa;
      case 'mental health':
        return Icons.self_improvement;
      case 'hydration':
        return Icons.water_drop;
      case 'fitness':
        return Icons.fitness_center;
      case 'sleep':
        return Icons.bedtime;
      case 'myth-buster':
        return Icons.lightbulb;
      case 'anemia':
        return Icons.bloodtype;
      case 'hygiene':
        return Icons.clean_hands;
      case 'heart health':
        return Icons.monitor_heart;
      case 'thyroid':
        return Icons.bolt;
      case 'from dr. deepika':
        return Icons.verified;
      default:
        return Icons.tips_and_updates;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, dd MMM').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconFor(_tip.category), color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isToday ? 'Tip of the Day' : 'Health Tip',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(_isToday ? dateStr : _tip.category,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_tip.category.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_tip.text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.45)),
          const SizedBox(height: 12),
          Row(
            children: [
              _TipAction(icon: Icons.shuffle, label: 'Another', onTap: _shuffle),
              const SizedBox(width: 8),
              _TipAction(icon: Icons.share, label: 'Share', onTap: _share),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TipAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
