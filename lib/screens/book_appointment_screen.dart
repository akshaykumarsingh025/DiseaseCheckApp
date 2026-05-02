import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/doctor_info.dart';

class BookAppointmentScreen extends StatelessWidget {
  const BookAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDoctorCard(isDark),
            const SizedBox(height: 20),
            _buildContactButtons(context),
            const SizedBox(height: 20),
            _buildClinicInfo(isDark),
            const SizedBox(height: 20),
            _buildSpecializations(isDark),
            const SizedBox(height: 20),
            _buildCredentials(isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.pink.shade100,
              child: Icon(Icons.local_hospital, size: 48, color: Colors.pink.shade700),
            ),
            const SizedBox(height: 16),
            Text(
              DoctorInfo.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              DoctorInfo.title,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              DoctorInfo.qualification,
              style: TextStyle(
                fontSize: 13,
                color: Colors.pink.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(DoctorInfo.experience, 'Experience'),
                _buildStatColumn(DoctorInfo.patients, 'Patients'),
                _buildStatColumn(DoctorInfo.rating, 'Rating'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildContactButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _launchUrl('tel:${DoctorInfo.phone}'),
          icon: const Icon(Icons.phone, size: 20),
          label: const Text('Call Now', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _launchUrl(DoctorInfo.whatsappUrl),
          icon: const Icon(Icons.chat, size: 20),
          label: const Text('WhatsApp', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _launchUrl(DoctorInfo.website),
          icon: const Icon(Icons.language, size: 20),
          label: const Text('Visit Website', style: TextStyle(fontSize: 16)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildClinicInfo(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clinic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, DoctorInfo.address),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, DoctorInfo.clinicHoursWeekday),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.access_time, DoctorInfo.clinicHoursSunday),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, DoctorInfo.email),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildSpecializations(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Specializations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ...DoctorInfo.specializations.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.pink.shade600),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentials(bool isDark) {
    return Card(
      color: isDark ? Colors.pink.shade900.withValues(alpha: 0.2) : Colors.pink.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.pink.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why Choose Dr. Deepika Singh?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildCredentialItem('MD & Senior Residency from AIIMS Delhi'),
            _buildCredentialItem('FCLS Certified - Laparoscopic Surgery'),
            _buildCredentialItem('MCCOG Certified - Cosmetic Gynecology'),
            _buildCredentialItem('Published Researcher - National & International Journals'),
            _buildCredentialItem('Member: FOGSI, AOGD, IFS, RCOG'),
            _buildCredentialItem('Ex-Senior Consultant: Max, Apollo, Sarvodaya'),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star, size: 14, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
