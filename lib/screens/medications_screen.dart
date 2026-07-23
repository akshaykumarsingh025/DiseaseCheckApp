import 'package:flutter/material.dart';

import '../services/medication_service.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  List<Medication> _meds = [];
  Set<String> _takenToday = {};
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meds = await MedicationService.getAll();
    final taken = await MedicationService.takenOn(DateTime.now());
    final streak = await MedicationService.currentStreak();
    if (!mounted) return;
    setState(() {
      _meds = meds;
      _takenToday = taken;
      _streak = streak;
      _loading = false;
    });
  }

  Future<void> _toggle(Medication med, String time, bool taken) async {
    await MedicationService.setTaken(med.id, time, DateTime.now(), taken);
    final t = await MedicationService.takenOn(DateTime.now());
    final streak = await MedicationService.currentStreak();
    if (!mounted) return;
    setState(() {
      _takenToday = t;
      _streak = streak;
    });
  }

  Future<void> _addOrEdit([Medication? existing]) async {
    final result = await showModalBottomSheet<Medication>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MedSheet(existing: existing),
    );
    if (result == null) return;
    if (result.name == '__delete__' && existing != null) {
      await MedicationService.delete(existing.id);
    } else {
      await MedicationService.upsert(result);
    }
    await _load();
  }

  int get _totalDosesToday =>
      _meds.where((m) => m.enabled).fold(0, (s, m) => s + m.times.length);

  int get _takenDosesToday {
    int c = 0;
    for (final m in _meds.where((m) => m.enabled)) {
      for (final t in m.times) {
        if (MedicationService.isSlotTaken(_takenToday, m.id, t)) c++;
      }
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medications & Supplements')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Medications & Supplements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: _meds.isEmpty
            ? _emptyState()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _summaryCard(),
                  const SizedBox(height: 16),
                  ..._meds.map(_medCard),
                  const SizedBox(height: 90),
                ],
              ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No medicines added yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
                'Add your medicines and supplements to get daily reminders and build a streak.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _addOrEdit(),
              style: FilledButton.styleFrom(backgroundColor: Colors.teal),
              icon: const Icon(Icons.add),
              label: const Text('Add medicine'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final total = _totalDosesToday;
    final taken = _takenDosesToday;
    final pct = total == 0 ? 0.0 : taken / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.teal.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Text('$taken/$total',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's doses",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                    total == 0
                        ? 'No doses scheduled'
                        : (taken == total
                            ? 'All done! Great job 🎉'
                            : '${total - taken} left to take'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orangeAccent, size: 18),
                    const SizedBox(width: 4),
                    Text('$_streak-day streak',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _medCard(Medication med) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.medication, color: Colors.teal.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (med.dosage.isNotEmpty)
                        Text(med.dosage,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (!med.enabled)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('Paused',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: Colors.grey,
                  onPressed: () => _addOrEdit(med),
                ),
              ],
            ),
            if (med.times.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('No times set',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: med.times.map((t) {
                  final taken =
                      MedicationService.isSlotTaken(_takenToday, med.id, t);
                  final label = _fmtTime(t);
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: med.enabled ? () => _toggle(med, t, !taken) : null,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: taken ? Colors.teal : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: taken ? Colors.teal : Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              taken
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: taken ? Colors.white : Colors.grey),
                          const SizedBox(width: 6),
                          Text(label,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: taken ? Colors.white : Colors.black87)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(String hhmm) {
    final p = hhmm.split(':');
    if (p.length != 2) return hhmm;
    final t = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    return t.format(context);
  }
}

/// Add/edit sheet for a medication.
class _MedSheet extends StatefulWidget {
  final Medication? existing;
  const _MedSheet({this.existing});

  @override
  State<_MedSheet> createState() => _MedSheetState();
}

class _MedSheetState extends State<_MedSheet> {
  late TextEditingController _name;
  late TextEditingController _dosage;
  late List<String> _times;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _dosage = TextEditingController(text: widget.existing?.dosage ?? '');
    _times = List.of(widget.existing?.times ?? const ['09:00']);
    _enabled = widget.existing?.enabled ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (picked != null) {
      final hhmm =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (!_times.contains(hhmm)) {
        setState(() {
          _times.add(hhmm);
          _times.sort();
        });
      }
    }
  }

  String _fmt(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]))
        .format(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(editing ? 'Edit medicine' : 'Add medicine',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g. Folic acid, Vitamin D, Metformin',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dosage,
              decoration: InputDecoration(
                labelText: 'Dosage (optional)',
                hintText: 'e.g. 1 tablet, 5000 IU',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Reminder times',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addTime,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add time'),
                ),
              ],
            ),
            if (_times.isEmpty)
              Text('No reminders — add at least one time.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _times.map((t) {
                  return Chip(
                    label: Text(_fmt(t)),
                    onDeleted: () => setState(() => _times.remove(t)),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.teal,
              title: const Text('Reminders on'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (editing)
                  TextButton.icon(
                    onPressed: () => Navigator.pop(
                        context,
                        Medication(
                            id: widget.existing!.id, name: '__delete__')),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label:
                        const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () {
                    final name = _name.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a name')),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
                      Medication(
                        id: widget.existing?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        dosage: _dosage.text.trim(),
                        times: _times,
                        enabled: _enabled,
                      ),
                    );
                  },
                  child: Text(editing ? 'Save' : 'Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
