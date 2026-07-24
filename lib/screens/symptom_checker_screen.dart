import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/ai_api_service.dart';
import '../utils/doctor_info.dart';

/// A guided, selection-only symptom checker for women's health.
///
/// The user picks symptoms from grouped options and answers a couple of
/// structured questions (duration, severity); there is no free-text chat, so
/// guidance stays strictly on the selected symptoms. It is not a diagnosis.
class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _scroll = ScrollController();

  final Set<String> _selected = {};
  String? _duration;
  String? _severity;
  bool _loading = false;
  String? _result;
  bool _urgent = false;

  /// Symptoms grouped by area. Everything the checker can talk about lives here,
  /// so it can never wander off-topic.
  static const Map<String, List<String>> _groups = {
    'Menstrual cycle': [
      'Irregular periods',
      'Missed period',
      'Heavy bleeding',
      'Painful cramps',
      'Spotting between periods',
    ],
    'Pain & discomfort': [
      'Pelvic pain',
      'Lower back pain',
      'Breast pain / tenderness',
      'Bloating',
    ],
    'Discharge & intimate': [
      'White discharge',
      'Coloured / foul-smelling discharge',
      'Itching or irritation',
      'Vaginal dryness',
    ],
    'Urinary': [
      'Burning when urinating',
      'Frequent urination',
      'Blood in urine',
    ],
    'Mood & PMS': [
      'Low mood / PMS',
      'Anxiety or irritability',
      'Fatigue',
      'Headache',
    ],
    'PCOS signs': [
      'Acne',
      'Excess hair growth',
      'Unexplained weight gain',
      'Hair thinning',
    ],
    'Pregnancy / menopause': [
      'Nausea or vomiting',
      'Cramping during pregnancy',
      'Hot flashes',
    ],
    'General': [
      'Fever',
      'Dizziness or fainting',
    ],
  };

  /// Symptoms that always warrant prompt medical attention.
  static const Set<String> _redFlags = {
    'Heavy bleeding',
    'Blood in urine',
    'Coloured / foul-smelling discharge',
    'Cramping during pregnancy',
    'Fever',
    'Dizziness or fainting',
  };

  static const List<String> _durations = [
    'Started today',
    'A few days',
    '1–2 weeks',
    'Over a month',
  ];

  static const List<String> _severities = ['Mild', 'Moderate', 'Severe'];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _canSubmit => _selected.isNotEmpty && !_loading;

  Future<void> _getGuidance() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _result = null;
    });

    final symptoms = _selected.join(', ');
    final urgent =
        _selected.any(_redFlags.contains) || _severity == 'Severe';

    final prompt =
        '''You are a caring women's-health assistant for a gynaecology clinic. Based ONLY on the structured symptom selection below, give brief, practical guidance. Do NOT ask any questions. Do NOT discuss anything unrelated to these symptoms or women's health.

Selected symptoms: $symptoms
Duration: ${_duration ?? 'not specified'}
Severity: ${_severity ?? 'not specified'}

Reply using EXACTLY these three headed sections, each with 2 to 4 short bullet points starting with "- ":
Possible related causes:
See a doctor soon if:
Simple self-care you can try:

Rules:
- Do NOT give a definitive diagnosis. Use wording like "may be related to".
- Keep every bullet short and in simple English.
- Do not add any text outside these three sections except a single closing line advising to consult ${DoctorInfo.name} for a proper check-up.''';

    final result = await AiApiService.generateText(prompt);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _urgent = urgent;
      _result = result.success && (result.text?.trim().isNotEmpty ?? false)
          ? _clean(result.text!)
          : _fallbackGuidance(symptoms, urgent);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  /// Strips markdown (heading `#` and bold `**`) so the guidance renders cleanly
  /// in plain text.
  String _clean(String s) {
    final lines = s.split('\n').map((l) {
      var t = l.replaceAll('**', '').replaceAll('__', '');
      t = t.replaceFirst(RegExp(r'^\s*#{1,6}\s*'), '');
      return t.replaceFirst(RegExp(r'^\s*[*•]\s+'), '- ');
    });
    return lines.join('\n').trim();
  }

  String _fallbackGuidance(String symptoms, bool urgent) {
    return 'Possible related causes:\n'
        '- Your selected symptoms ($symptoms) can have several common causes and often settle on their own.\n\n'
        'See a doctor soon if:\n'
        '- The symptoms get worse, last longer than expected, or you feel very unwell.\n'
        '${urgent ? '- Some of what you selected can be serious — please seek care promptly.\n' : ''}\n'
        'Simple self-care you can try:\n'
        '- Rest, stay hydrated, and track when the symptoms happen.\n\n'
        'Please consult ${DoctorInfo.name} for a proper check-up.';
  }

  void _reset() {
    setState(() {
      _selected.clear();
      _duration = null;
      _severity = null;
      _result = null;
      _urgent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
        actions: [
          if (_selected.isNotEmpty || _result != null)
            TextButton(
              onPressed: _reset,
              child: const Text('Reset'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _disclaimer(),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    'Select the symptoms you\'re experiencing, then get general guidance.',
                    style:
                        TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in _groups.entries) _group(entry.key, entry.value),
                  const SizedBox(height: 8),
                  _questionHeader('How long have you had these?'),
                  _choiceRow(_durations, _duration,
                      (v) => setState(() => _duration = v)),
                  const SizedBox(height: 12),
                  _questionHeader('How severe does it feel?'),
                  _choiceRow(_severities, _severity,
                      (v) => setState(() => _severity = v)),
                  const SizedBox(height: 20),
                  if (_result != null) ...[
                    _resultCard(),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _disclaimer() {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'General guidance only — not a medical diagnosis.',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(String title, List<String> symptoms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: symptoms.map((s) {
            final selected = _selected.contains(s);
            return FilterChip(
              label: Text(s),
              selected: selected,
              showCheckmark: true,
              selectedColor: Colors.pink.shade100,
              checkmarkColor: Colors.pink.shade700,
              labelStyle: TextStyle(
                fontSize: 13,
                color: selected ? Colors.pink.shade900 : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (v) => setState(() {
                if (v) {
                  _selected.add(s);
                } else {
                  _selected.remove(s);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _questionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child:
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _choiceRow(
      List<String> options, String? value, ValueChanged<String?> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final selected = value == o;
        return ChoiceChip(
          label: Text(o),
          selected: selected,
          selectedColor: Colors.pink.shade100,
          labelStyle: TextStyle(
            fontSize: 13,
            color: selected ? Colors.pink.shade900 : null,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
          onSelected: (_) => onChanged(selected ? null : o),
        );
      }).toList(),
    );
  }

  Widget _resultCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_urgent)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Some of what you selected can be serious. Please seek medical care promptly.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.health_and_safety,
                        color: Colors.pink.shade400, size: 20),
                    const SizedBox(width: 8),
                    const Text('Guidance',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                SelectableText(
                  _result!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F3460),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => context.push('/online-opd'),
          icon: const Icon(Icons.local_hospital),
          label: const Text('Consult ${DoctorInfo.name}'),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selected.isEmpty
                  ? 'Select at least one symptom'
                  : '${_selected.length} symptom${_selected.length == 1 ? '' : 's'} selected',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            onPressed: _canSubmit ? _getGuidance : null,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(_result == null ? 'Get guidance' : 'Update'),
          ),
        ],
      ),
    );
  }
}
