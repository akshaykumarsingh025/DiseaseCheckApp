import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/doctor_info.dart';
import '../../widgets/nav_tile.dart';

/// The "Consult" tab: the doctor front-and-centre, appointments, prescriptions
/// and health reading material.
class ConsultTab extends StatelessWidget {
  const ConsultTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _doctorHero(context),
        const SizedBox(height: 16),
        NavTile(
          icon: Icons.event_available,
          color: Colors.blue,
          title: 'Book Appointment',
          subtitle: 'Pick a slot for your OPD visit',
          onTap: () => context.push('/book-appointment'),
        ),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.medical_information,
          color: Colors.teal.shade700,
          title: 'My Prescriptions',
          subtitle: 'Download prescriptions from your consultations',
          onTap: () => context.push('/my-prescriptions'),
        ),
        const SectionHeader('Learn'),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.article_outlined,
          color: Colors.indigo,
          title: "Women's Health News",
          subtitle: 'Live headlines & verified updates',
          onTap: () => context.push('/womens-health-news'),
        ),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.spa_outlined,
          color: Colors.teal,
          title: 'Natural Remedies',
          subtitle: 'Herbal & natural remedy updates',
          onTap: () => context.push('/natural-remedies'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _doctorHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [Colors.pink.shade500, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                child: const Icon(Icons.local_hospital,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(DoctorInfo.name,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(DoctorInfo.qualification,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('${DoctorInfo.experience} · ${DoctorInfo.patients} patients',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _action(
                  icon: Icons.videocam,
                  label: 'Video ₹111',
                  primary: true,
                  onTap: () => context.push('/online-opd'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _action(
                  icon: Icons.phone,
                  label: 'Call',
                  onTap: () => _launch('tel:${DoctorInfo.phone}'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _action(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  onTap: () => _launch(DoctorInfo.whatsappUrl),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Material(
      color: primary ? Colors.white : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: primary ? Colors.pink.shade600 : Colors.white),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primary ? Colors.pink.shade600 : Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }
}
